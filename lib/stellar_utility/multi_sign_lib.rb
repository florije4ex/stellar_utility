#(c) 2015 by sacarlson  sacarlson_2000@yahoo.com
#this is the lib used by the multi-sign-server and multi-sign-websocket
# should we merge this with stellar_utility?
require 'json'
require 'sqlite3'
require 'yaml'
require 'base32'
require '../lib/stellar_utility/stellar_utility.rb'


class Multi_sign

   attr_accessor :configs, :db, :Utils

  def initialize(configs)  
    # Instance variables 
    @configs = configs  
    #puts "db file: #{@configs["db_file_path"]}"
    @db = SQLite3::Database.open @configs["mss_db_file_path"]
    @db.execute "PRAGMA journal_mode = WAL"
    @db.results_as_hash=true
    @Utils = Stellar_utility::Utils.new()
    puts "Utils version: #{@Utils.version}"
    puts "configs: #{@Utils.configs}"
    #@conn
  end  

  def version()
    version = "su: "+@Utils.version+"  mss_version: " + @configs["version"] + " core_version: " + @configs["core_version"]
  end

  def get_db(query="none")
    #puts "q: #{query}"
    #returns query hash from database that is dependent on mode
    if @configs["mss_db_mode"] == "sqlite"
      #puts "db file: #{@configs["db_file_path"]}"
      #db = SQLite3::Database.open @configs["db_file_path"]  
      stm = @db.prepare query 
      result= stm.execute
      return result
    elsif @configs["mss_db_mode"] == "postgres"
      #postgress is untested
      conn=PGconn.connect( :hostaddr=>@configs["pg_hostaddr"], :port=>@configs["pg_port"], :dbname=>@configs["pg_dbname"], :user=>@configs["pg_user"], :password=>@configs["pg_password"])
      result = conn.exec(query)
      conn.close
      #puts "rusult class #{result.class}"
      if result.cmd_tuples == 0
        return nil
      else
        return result
        #return result[0]
      end
    else 
      puts "no such mode #{@configs["mss_db_mode"]} for db query error"
      exit -1
    end
  end

  def add_tx(hash)
    #hash = {"action"=>"submit_tx","tx_title"=>"test tx", "signer_address"=>"RUTIWOPF", "signer_weight"=>"1", "master_address"=>"GAJYPMJ...","tx_envelope_b64"=>"AAAA...","signer_sig_b64"=>""}
    #tx_code = "T_"+hash32(hash["tx_envelope_b64"])
    tx_code = @Utils.envelope_to_txid(hash["tx_envelope_b64"])
    query = "INSERT or IGNORE INTO Multi_sign_tx VALUES(NULL,0,'#{tx_code}','#{hash["tx_title"]}','#{hash["signer_address"]}','#{hash["signer_weight"]}','#{hash["master_address"]}','#{hash["tx_envelope_b64"]}','#{hash["signer_sig_b64"]}');"
    get_db(query)
    return check_tx_status(tx_code,level="high")
  end

  def sign_tx(hash)
    #hash = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAA...","signer_sig_b64"=>"JIDYR..."}
    if @Utils.verify_signature(hash["tx_envelope_b64"], hash["signer_address"], hash["signer_sig_b64"])
      query = "INSERT or IGNORE INTO Multi_sign_tx VALUES(NULL,1,'#{hash["tx_code"]}','#{hash["tx_title"]}','#{hash["signer_address"]}', '#{hash["signer_weight"]}','#{hash["master_address"]}','#{hash["tx_envelope_b64"]}','#{hash["signer_sig_b64"]}');"
      get_db(query)
      result = check_tx_status(hash["tx_code"],level="high")
      result["last_signer"] = hash["signer_address"]
    else
      result = {"status" => "bad_signature"}
      result["tx_code"] = hash["tx_code"]
      result["signer_address"] = hash["signer_address"]
      result["signer_sig_b64"] = hash["signer_sig_b64"]
      result["tx_envelope_b64"] = hash["tx_envelope_b64"]
    end
    return result
  end

  def add_acc(acc_hash)
    #acc_hash = {"action"=>"create_acc", "tx_title"=>"TP5NV7WN53", "master_address"=>"GDKQJNX4DQRHVE76ZOIGQSYZR2PDX4XSDT3CAKM7F6NSZBOQ6D5QDLBD", "master_seed"=>"SDEH6BEVCMLFGAO5SAOQOWVDIFT5XS466OJQ3CZEU6OSYOXJPQQ66CYR", "start_balance"=>41, "signers_total"=>3, "thresholds"=>{"master_weight"=>1, "low"=>"0", "med"=>3, "high"=>3}, "signer_weights"=>{"GA2F3NNTSJEX2L7QJHPS4GMSQKGUMKZESTUIRXUZLHZXSQGBNBIJCMET"=>1, "GBCGQWBATTLZW6PWX7H4TNRDDWDFCZAWCGTXWYPHRHRS534HMC5HXWUY"=>1}}
    #puts "acc_hash: #{acc_hash}"
    query = "INSERT or REPLACE INTO Multi_sign_acc VALUES(NULL,'#{acc_hash["tx_title"]}','#{acc_hash["master_address"]}','#{acc_hash["master_seed"]}','#{acc_hash["signers_total"]}');"
    #puts "query: #{query}"
    #puts "class get_db: #{get_db.class}"
    #query2 = "SELECT * FROM Acc_threshold_levels WHERE master_address = 'test'"
    get_db(query)
    query = "INSERT or REPLACE INTO Acc_threshold_levels VALUES(NULL,'#{acc_hash["master_address"]}','#{acc_hash["thresholds"]["master_weight"]}','#{acc_hash["thresholds"]["low"]}','#{acc_hash["thresholds"]["med"]}','#{acc_hash["thresholds"]["high"]}');"
    get_db(query)
    signers = acc_hash["signer_weights"].to_json
    #query = "INSERT or IGNORE INTO Acc_signers VALUES(NULL,'#{acc_hash["master_address"]}','#{signers}');"
    query = "INSERT or REPLACE INTO Acc_signers VALUES(NULL,'#{acc_hash["master_address"]}','#{signers}');"
    #puts "query: #{query}"
    get_db(query)
    #if the funds are available we will make needed changes to thresholds
    @Utils.create_account_from_acc_hash(acc_hash)
    return get_acc_mss(acc_hash["master_address"])
  end

  def create_db(db_file_path=@configs["mss_db_file_path"])
    #create_acc = {"action"=>"create_acc","tx_title"=>"first multi-sig tx","master_address"=>"GDZ4AF...","master_seed"=>"SDRES6...","signers_total"=>"2", "thresholds"=>{"master_weight"=>"1","low"=>"0","med"=>"2","high"=>"2"},"signer_weights"=>["GDZ4AF..."=>"1","GDOJM..."=>"1"]}
    #submit_tx = {"action"=>"submit_tx","tx_title"=>"test multi sig tx","master_address"=>"GDZ4AF...", "tx_envelope_b64"=>"AAAA..."}
    #sign_tx = {"action"=>"sign_tx","tx_title"=>"test tx","tx_code"=>"JIEWFJYE", "signer_address"=>"GAJYGYI...", "signer_weight"=>"1", "tx_envelope_b64"=>"AAAA..." "signer_sig_b64"=>"JIEYS..."}
    db = SQLite3::Database.open db_file_path
    db.execute "CREATE TABLE IF NOT EXISTS Multi_sign_acc(acc_num INTEGER PRIMARY KEY, 
        tx_title TEXT, master_address TEXT UNIQUE, master_seed TEXT, signers_total TEXT);"
    db.execute "CREATE TABLE IF NOT EXISTS Acc_threshold_levels(acc_num INTEGER PRIMARY KEY, master_address TEXT UNIQUE, 
        master_weight TEXT,low TEXT, med TEXT, high TEXT);"
    db.execute "CREATE TABLE IF NOT EXISTS Acc_signers(acc_num INTEGER PRIMARY KEY, master_address TEXT UNIQUE, signers TEXT);"
    # signer = 1 for being a signer of a tx, signer = 0 for being the master writer of the tx
    db.execute "CREATE TABLE IF NOT EXISTS Multi_sign_tx(tx_num INTEGER PRIMARY KEY, signer INTEGER, tx_code TEXT, tx_title TEXT,signer_address TEXT,signer_weight TEXT, master_address TEXT, tx_envelope_b64 TEXT,signer_sig_b64 TEXT);"
    db.execute "CREATE TABLE IF NOT EXISTS Witness(id_num INTEGER PRIMARY KEY, address TEXT, timebound DATETIME, event_datetime DATETIME);"

  end




  def get_acc(search_hash)  
    #search_hash = {"table"=>"Multi_sign_acc", "where"=>"master_address", "value"=>"GDZ4AF...","select"=>"*"}
    query = "SELECT #{search_hash["select"]} FROM #{search_hash["table"]} WHERE #{search_hash["where"]} = '#{search_hash["value"]}'"
    #puts "query: #{query}"
    rs = get_db(query)
    #puts "rs.inspect:  #{rs.inspect}"
    #puts "rs.next:  #{rs.next}"
    return rs.next
  end

  def get_acc_mss(master_address,acc_num=0)
    search_hash = {"table"=>"Multi_sign_acc", "where"=>"master_address", "value"=>"GDZ4AF...","select"=>"*"}
    if acc_num == 0
      #puts "master_address:  #{master_address}"
      search_hash["value"] = master_address
      return get_acc(search_hash) 
    else
      search_hash["value"] = acc_num
      search_hash["where"] = "acc_num"
      return get_acc(search_hash) 
    end
  end

  def get_acc_threshold_levels(master_address)
    query = "SELECT * FROM Acc_threshold_levels WHERE master_address = '#{master_address}'"
    rs = get_db(query)
    rs.next
  end

  def get_acc_signers(master_address,acc_num=0)
    #this is deprecated
    #Utils.get_signer_info(target_address,signer_address="")  should be used instead that gets it direct from stellar network db
    query = "SELECT * FROM Acc_signers WHERE master_address = '#{master_address}'"
    rs = get_db(query)
    result = rs.next
    if result== nil
      return nil
    end
    JSON.parse(result["signers"])
  end

  def get_Tx(tx_code)
    #this returns the master created transaction with added info,  
    #{"tx_num"=>1, "signer"=>0, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test multi sig tx", "signer_address"=>"", "signer_weight"=>"", "master_address"=>"GDZ4AFAB...", "tx_envelope_b64"=>"AAAA...","signer_sig_b64"=>"URYE..."}
    if tx_code == "last"
      query = "SELECT * FROM Multi_sign_tx WHERE tx_num = (SELECT MAX(tx_num) FROM Multi_sign_tx);"
    else
      query = "SELECT * FROM Multi_sign_tx WHERE tx_code = '#{tx_code}' AND signer = '0';"
    end
    rs = get_db(query)
    result = rs.next
    if result== nil
      return nil
    end
    return result
  end

  def get_Tx_signed(tx_code)
    #this will return an array of signer records,  need rs.each do |row| from returned data
    #{"tx_num"=>2, "signer"=>1, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test tx", "signer_address"=>"GAJYGYIa...", "signer_weight"=>"1", "master_address"=>"", "tx_envelope_b64"=>"AAAAzz...","signer_sig_b64"=>"RUYHFY..."}
    query = "SELECT * FROM Multi_sign_tx WHERE tx_code = '#{tx_code}' AND signer = '1';"
    rs = get_db(query)
  end

  def hash32(string)
    #a shortened 10 letter base32 SHA256 hash, not likely to be duplicate with small numbers of tx
    # example output "7ZZUMOSZ26"
    # this is duplicated in Stellar_utility::Utils, if we change this remember to change the other
    #Base32.encode(Digest::SHA256.digest(string))[0..7]
    @Utils.hash32(string)
  end

  def send_multi_sig_tx(tx_code)
    send_multi_sig_tx_v2(tx_code)
  end

  def send_multi_sig_tx_v1(tx_code)
    #old version probly delete later, it worked but just takes more data space to send
    # whole envelope instead of just signatures so  a bit more bandwidth needed and ??
    if tx_code == "7ZZUMOSZ26"
      puts "test mode disable send_multi_sig_tx"
      return
    end
    # this will merge all signed transaction for transaction tx_code and send it to stellar network for processing
    tx = get_Tx(tx_code)
    #{"tx_num"=>2, "signer"=>1, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test tx", "signer_address"=>"GAJYGYIa...", "signer_weight"=>"1", "master_address"=>"", "tx_envelope_b64"=>"AAAAzz...", "signer_sig_b64"=>""}
    signed = get_Tx_signed(tx_code)
    env_master_b64 = tx["tx_envelope_b64"]
    env_master = @Utils.b64_to_envelope(env_master_b64)
    #total = levels["master_weight"].to_i
    env_array = []
    env_array[0] = env_master
    puts ""
    puts "env_master:  #{env_master.inspect}"
    pos = 1
    signed.each do |row|
      #puts "env_b64: #{row["tx_envelope_b64"]}"
      newenv = @Utils.b64_to_envelope(row["tx_envelope_b64"])
      puts ""
      puts "newenv:  #{newenv.inspect}"
      env_array[pos] = newenv
      pos = pos + 1
    end
    puts "env_array.length:  #{env_array.length}"
    env_master = @Utils.envelope_merge(env_array)
    puts ""
    puts "env_send:  #{env_master.inspect}"
    b64 = @Utils.envelope_to_b64(env_master)
    puts "send_tx"
    #result = @Utils.send_tx(b64)
    puts "result send_tx #{result}"
    return result
  end

  def send_multi_sig_tx_v2(tx_code)
    #this version uses just signatures instead of envelopes in tx_code return to merge
    if tx_code == "7ZZUMOSZ26"
      puts "test mode disable send_multi_sig_tx"
      return
    end
    # this will merge all signed transaction for transaction tx_code and send it to stellar network for processing
    tx = get_Tx(tx_code)
    #{"tx_num"=>2, "signer"=>1, "tx_code"=>"7ZZUMOSZ26", "tx_title"=>"test tx", "signer_address"=>"GAJYGYIa...", "signer_weight"=>"1", "master_address"=>"", "tx_envelope_b64"=>"AAAAzz...", "signer_sig_b64"=>""}
    signed = get_Tx_signed(tx_code)
    env_master_b64 = tx["tx_envelope_b64"]
    env_master = @Utils.b64_to_envelope(env_master_b64)
    #total = levels["master_weight"].to_i
    sig_array = []
    sig_master = env_master.signatures
    if sig_master.length > 1
      sig_master = sig_master[0]
      sig_master = [sig_master]
    end
    sig_array[0] = sig_master[0]
    #puts ""
    #puts "env_master:  #{env_master.inspect}"
    pos = 1
    signed.each do |row|
      #puts "sig_b64: #{row["signer_sig_b64"]}"
      # comes from this
      #sig_b64 = signature[0].to_xdr(:base64)
      bytes = Stellar::Convert.from_base64(row["signer_sig_b64"])
      newsig = Stellar::DecoratedSignature.from_xdr bytes
      #puts ""
      #puts "newsig:  #{newsig.inspect}"
      sig_array[pos] = newsig
      pos = pos + 1
    end
    #puts ""
    #puts "sig_array.length:  #{sig_array.length}"
    #puts "sig_array.inspect:  #{sig_array.inspect}"
    env_master = @Utils.merge_signatures_tx(env_master.tx,sig_array)
    #env_master = @Utils.envelope_merge(env_array)
    #puts ""
    #puts "env_send:  #{env_master.inspect}"
    b64 = @Utils.envelope_to_b64(env_master)
    puts "send_tx"
    result = @Utils.send_tx(b64)
    puts "result send_tx #{result}"
    return result
  end

  def check_tx_status(tx_code,level=:high)
    #this will see if the multi-sign transaction with this tx_code has the needed signitures to be processed
    #at this time only checks one level at a time with default threshold high to have met needed signature count
    tx = get_Tx(tx_code)
    puts "tx: #{tx}"
    #levels = get_acc_threshold_levels(tx["master_address"])
    if level == "high"
      level = :high
    end
    levels = @Utils.get_thresholds_local(tx["master_address"])
    #{:master_weight=>1, :low=>0, :medium=>2, :high=>2}
    #puts "#{levels}"
    need = levels[level].to_i
    #puts "need: #{need}"
    signed = get_Tx_signed(tx_code)
    #tx["tx_envelope_b64"]
    total = levels["master_weight"].to_i
    signed.each do |row|
      total = total + row["signer_weight"].to_i
      #puts "row: #{row["signer_weight"].to_i}"
    end
    #puts "total weights #{total}"
    if total >= need
      send_multi_sig_tx(tx_code)
      retval = {"status"=>"ready"}
      retval["tx_code"] = tx_code
      #retval["signer_count"] = total
      #retval["count_needed"] = need
      return retval
    else
      retval = {"status"=>"pending"}
      retval["tx_code"] = tx_code
      retval["signer_count"] = total
      retval["count_needed"] = need
      return retval
    end
  end

  def get_account_info(account)
    @Utils.get_accounts_local(account)
  end

  def timestamp_witness(address,timebound)
    #record the time this address had it's timebound timestamped, used in make_witness function
    #also checks to see if a timebound was already recorded that has not expired yet,
    #if unexpired timebound is found it will return the record, if no unexpired timebounds found returns nil
    address = @Utils.convert_keypair_to_address(address)
    #db.execute "CREATE TABLE IF NOT EXISTS Witness(id_num INTEGER PRIMARY KEY, address TEXT, timebound DATETIME, event_datetime DATETIME);"
    puts "time.now:  #{Time.now.to_i}"
    if timebound < Time.now.to_i
      puts "timebound is < Time.now so not going to timestamp or witness it, nothing done"
      return nil
    end
    query = "SELECT * FROM Witness WHERE address = '#{address}' and timebound > #{Time.now.to_i};"
    rs = get_db(query)
    rs1 = rs.next
    if rs1.nil?
      puts "got here so new timebound set"
      query = "INSERT INTO Witness  VALUES (NULL,'#{address}','#{timebound}', strftime('%s','now'));"
      get_db(query)
    end
    return rs1
  end

  def make_witness_unlock(witness_keypair,account,timebound,asset=nil,issuer=nil)
    #create a timebound timestamped witness document for address in account, signed witnessed by witness_keypair
    #include in the witnessed document what is seen in trustlines for assets of issuer
    check = @Utils.create_unlock_transaction(account,witness_keypair,timebound)
    if check["status"]=="fail"
      return check
    end
    timestamp = timestamp_witness(account,timebound)
    results ={}
    puts "timestamp: #{timestamp}"
    if timestamp.nil?
      puts "timestamp is nil so timebound is unchanged at #{timebound}"      
    else
      timebound = timestamp["timebound"]
    end
    results = @Utils.make_witness_hash(witness_keypair,account,timebound,asset,issuer)
    results["unlock"] = @Utils.create_unlock_transaction(account,witness_keypair,timebound)
    puts "witness: #{results}"
    return results
  end

end #end class Multi_sign

