# stellar_utility
a set of examples to setup transactions on the new stellar-core and a small utility lib that I setup and used to learn with 

The examples here are meant to be run when you are running a local standalone stellar-core on your system.
but now the new version of stellar-utility supports the horizon API interface so a local stellar-core is no longer needs on the client side.
you can still run a local core by haveing the url_stellar_core value correct in the stellar_utilities.cfg file.  Also added at
 ./stellar-db/ are scripts and stellar-core configs I used to do first start ups of stellar-core. run start_core.sh from the directory you plan to have the sqlite database,  or if that fails after first install or any upgrade pulls for stellar-core try reset_core.sh

note: this was writen in my attempts to learn how to use ruby-stellar-base.  I think later I may find
that stellar_core_commander is a better path to start to learning stellar-core features with after we figure out how to configure and use it with a localy hosted stellar-core.  Much of the code in the stellar_utility.rb lib was pulled and ported from what I found and needed in stellar_core_commander sections.  maybe someday I'll port or repackage a stellar_core_commander_lite edition where not all the fancy stuff is needed to be mostly used to integrate into other aplications.  I would also like to add a way to not only point controls to a localhosted stellar-core or docker core, but also send transactions through to the horizon website api interface with the commander as I now do with stellar_utility now.  When I get that all figured out maybe I'll also add it to this repository as a reference for others to learn from.

#working examples included:

create_account.rb
 sets up a new active random account with funding from the default master account
 
send_native.rb
  demonstrates sending native lunes from one account to another
  
send_non_native.rb
  demonstrates sending non native currency "USD" in this case from one account to another
  
create_offers.rb
  demonstrates setting up order offers on the stellar-core network
  
there are many other examples most of them working at one point or another.
note at this point we do have the horizon interface also working that is selectable from changes made in stellar_utility.cfg file.
The config file is in need of documentation that I also haven't goten to.  The configs allows making many changes to point at old and new versions of
stellar using different typs of databases including sqlite3 and postgres support. We now also support the open-core branched network.


# Multi Sign Server

The bigest addition in this system set is called the multi-sign-server system that is a set of files with the server and demo examples ilistrating it's usage.
it is used to create and share multi sign accounts and multi sign transactions.  it's strictly an API json restclient interface not realy meant for direct humans to be running. it's the planed infrastructure that will be used in the upgraded pokerth_accounting system.
It is now fully documented and for the most part finalized as seen bellow.
to simplify in summery, multi-sign-server is a place where users can publish multi sign accounts and then publish transaction that other users can find, pick them up, and sign them and send back there signings to the mss-server.
The server collects all the needed signatures and will auto submit the transaction when the threshold of needed signers is reached.
    
The main files and examples in multi-sign-server (also called mss-server) system collection explained:

multi-sign-server/multi-sign-server.rb:
  is the central server of the mss-server system that runs and listens on port 9494 by default
  it has a Json API interface see bellow for details of setup and operation. 


multi-sign-server/create_account_for_mss.rb
  that demonstrates how a client master account creator can create a multi signed account and then published it on the mss-server

multi-sign-server/submit_transaction_to_mss.rb
  that demonstrates how the master account created in create_account_for_mss.rb can be used to create a multi signed transaction and publish it to the mss-server

multi-sign-server/sign_transaction_mss.rb
  That demonstrates how signer clients would pickup the published transactions from mss-server, sign them and send them back to the mss-server that continues to 
  collect and count the signitures and when enuf collected the mss-server submits the transactions to the stellar network to be verified.



#Multi Sign Server also know as mss-server operation details

multi-sign-server.rb is a JSON formated API server for the stellar.org networks new stellar-core
it was originaly created to allow the publishing of multi sign transaction and provide a point of collection for the 
signers to pickup the original unsigned transaction, sign it and send a validation signature back to the mss-server
that would collect all the signatures and when weighted threshold is met will send the multi signed transaction to the stellar-core network

The mss-server can now also do some basic stellar network function of getting account balance, sending tx blobs and other functions that are normaly
done through the horizon server API.


#The mss-server json action commands and format

An example of a basic JSON formated string that is sent to the mss-server looks like this
{"action":"send_tx","tx_code":"T_RQHKC7XD"}

In this case the "action" code is send_tx that needs one verible tx_code to perform the action of sending this tx_code transaction to the
stellar network to get a responce returned that will also be in JSON format.

The present action codes and values required for each of them can be seen bellow in the format:

#action_code:    short explaination of what the action code does
  Values sent: bellow will be the values we send the mss-server in JSON format
    value_name:  short explaination of what the value name is and does for the action_code
       .        as many values as needed for an action
       .
  Value returned: bellow will be what the mss-server returns in JSON format
    value_name: short explaination of what the value name is and does for the action_code
       .       as many returned for this action
       .

 example JSON sent:  showing examples of what is sent of this action in JSON format 
 example JSON returned:  examples of JSON string returned from mss-server for this action

#create_acc: create a multi sign account with the settings of the values given
  Values sent:
    master_address: the stellar address of the master creator of the account
    master_seed:    optional master seed of the master creator of the account (not really needed at this time)
    signers_total:  total number of signers that will be added to the account
    thresholds:     threshold settings on the account including
       master_weight: the signing weight of the master account seed as a signer
       low:           the threshold for the low setting on this multi sign account
       med:           the threshold for the med setting 
       high:          the threshold for the high setting 

  Values returned:
    acc_num:  integer of local tx index on this mss-server (not uneque between mss-servers)
    tx_title: what is now seen as tx_title on this transaction defaults to random 8 letter hash leading with A_
    master_address:  master_address of what was used to create this account
    master_seed: master_seed of account that created this account (none really needed)
    start_balance: setting that were set or defaulted as what to fund the master_address account if created on mss-server
    signers_total: the number of signers that have been attached to this account
    thresholds:
      master_weight: master_weight signing settings for the master_address account
      master_weight: the signing weight of the master account seed as a signer
       low:           the threshold for the low setting on this multi sign account
       med:           the threshold for the med setting 
       high:          the threshold for the high setting
 
 example in JSON sent:
{"action":"create_acc","tx_title":"A_M7U2T7UQ","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","master_seed":"SABKMP7S2A5QUQ2DHNV7HO53EJWUGO7C2BF3WU2RL3YCLGFFCNUOF4KA","start_balance":100,"signers_total":3,"thresholds":{"master_weight":1,"low":"0","med":3,"high":3},"signer_weights":{"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U":1,"GCFZMOSTNINJB65VOSXY3RKATANT7DQJJVUMJGSXMCAOBUUENSQME4ZZ":1}}
 
 example in JSON return:
{"acc_num":1,"tx_title":"A_M7U2T7UQ","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","master_seed":"none_provided","signers_total":"3"}

#send_tx:    send the transaction with this matching tx_code to the stellar-core network for validation (normaly done automaticaly but for test we have this) 
  Values sent: 
    tx_code:  is a uneque auto generated code number that starts with T_ example T_RQHKC7XD that are used as references to transactions in the mss-server database

  Values returned:
    name:  stellar network error name
    value: value integer of stellar error code

 example returned:
 {"name":"tx_bad_seq","value":-5}  //this is what error output looks like if bad transaction sent

#status_tx:  return the status of the transaction in the mss-server db that matches tx_code to find out how many signatures collected or if tx already sent
  Value sent:
    tx_code: 

  Values returned:
    status: returns pending if not enuf sigs recieved to send transaction, ready if tx has already been sent to network
    tx_code:

 example JSON send: 
 {"action":"status_tx","tx_code":"T_RQHKC7XD"}
 example JSON return:
 {"status":"pending","tx_code":"T_RQHKC7XD"} // tx hasn't got all it signatures needed yet
 {"status":"ready","tx_code":"T_RQHKC7XD"}  // this will return if the tx has already been sent to stellar-core network for validation
 
#submit_tx:  adds a new transaction to the mss-server database with the added values of the veribles attached
  Values sent:
    tx_title: an added modifiable title used to help users discribe the transaction, defaults to tx_code 
    master_address: the stellar multi sign account number
    tx_envelope_b64: the transaction envelope to be signed by the signers in xdr base 64 format
    signer_weight:  the signing weight given to the master_address
    tx_code:  is not entered but is autocreated and added to the mss-server database and returned in responce

  Values returned:
    status: pending or ?? when after the system has sent the transaction to the stellar network for validation
    tx_code: 
    signer_count:  number of signers that have already signed this transaction (including the master)
    count_needed: the total number of signers needed for this transaction to be sent to the stellar network for validation
    

 example JSON send:
{"action":"submit_tx","tx_title":"T_JD7NBZPV","signer_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","signer_weight":"1","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAADAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q1NjkyAAAAAAAAAAAAAAABN/eQXAAAAEBaa64v1Pvh3g0eM1w5g9tlli/O6J0T4FPu9ifle3xGDyOLvGo7W2bpZ+uS9q31se2UMbd5gr0HFPivvuZyanYL","signer_sig_b64":""}

 example JSON returned:
{"status":"pending","tx_code":"T_JD7NBZPV","signer_count":1,"count_needed":3}

#get_tx: lookup and return the values found for the transaction with this tx_code from the mss-server database
  Values sent:
    tx_code:

  Values returned:
    tx_num: an integer tx number used as index on the local mss-server
    signer: set to 0 if it was signed by master_address, 1 if signed by a signer
    tx_code: uneque code created as an indentifier to search for transactions over all mss-servers
    tx_title: user definable to help users explain or identify what the transaction is or what it's for
    signer_address: a stellar address in base 32 of a signer if this index identifies a signer entry
    signer_weight: signing weight that this signer has in this transaction
    master_address: master address of the creator of this transaction
    tx_envelope_b64: a stellar formated tx envelope in xdr base64 format of the transaction that need to be signed. 


 example JSON send:
{"action":"get_tx","tx_code":"T_RQHKC7XD"}

 example return from get_tx:
{"tx_num":1,"signer":0,"tx_code":"T_RQHKC7XD","tx_title":"T_RQHKC7XD","signer_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","signer_weight":"1","master_address":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAACAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q3NDM2AAAAAAAAAAAAAAABN/eQXAAAAEB2xFD4v6goEazu9UeLY0naWENxGwDKktFquSF0MJN6MPYrucRuRFzYK/xRofZzl8EIljizva+XBEk/SRioh6QL","signer_sig_b64":""}

#sign_tx: add a signature to a transaction that is already in the mss-server, if no tx_code match is found nothing is done
  Values sent:
    tx_code:
    signer_address: the stellar public address of this signer in base32 format example GCYFPRSLB...
    signer_weight: the signing weight of this signer (default is 1)
    tx_title: customisable by the user to add details for other users, not really used by the software
    signer_sig_b64: the validation signature for this transaction by this signer in xdr base 64 format
    tx_envelope_b64: optional (no longer used in v2) a signed envelope of the transaction in xdr base 64 format, v2 only needs signer_sig_b64 instead

  Values returned:
    status: pending returned if transaction not yet processed by stellar network, ready returned if needed signers have signed tx and tx already sent to network
    tx_code:  
    
example JSON sent:
{"action":"sign_tx","tx_title":"T_RQHKC7XD","tx_code":"T_RQHKC7XD","signer_address":"GCHOUZUXO2CKBJJICJ6R4EHRLSKCANGD3QTACE5QZJ27T7TSGMD4JP5U","signer_weight":"1","tx_envelope_b64":"AAAAANnoheGY8bwTfUfWundrfxGT689BSdQV6JmER2Q395BcAAAACgABh04AAAACAAAAAAAAAAAAAAABAAAAAAAAAAUAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAACHRlc3Q3NDM2AAAAAAAAAAAAAAACcjMHxAAAAEApyJ3gfjYOZaAzY4ZLnt7uJCPrLlR1cPAos4fMRyrBrF2yrfz6U3dsAbv8tpmCMISiS9vZtKExaDZnsqdB1jcEN/eQXAAAAEB2xFD4v6goEazu9UeLY0naWENxGwDKktFquSF0MJN6MPYrucRuRFzYK/xRofZzl8EIljizva+XBEk/SRioh6QL","signer_sig_b64":"cjMHxAAAAEApyJ3gfjYOZaAzY4ZLnt7uJCPrLlR1cPAos4fMRyrBrF2yrfz6U3dsAbv8tpmCMISiS9vZtKExaDZnsqdB1jcE"}

example JSON returned:
{"status":"ready","tx_code":"T_RQHKC7XD"}

#get_account_info: dump all data found in stellar-core db in account table. this will not work if mss-server is running in horizon mode
  Values sent:
    account: stellar address base 32 example GC3IIU5Q...

  Values returned:
    accountid: same as account address base 32 
    balance:  native balance seen in stellar network in lumens or STR or ??, it is in integer format so value is divided by 1e7 I think to be correct
    seqnum: sequence number of this account as seen on the stellar network
    numsubentries: the number of added signers that are attached to this account
    inflationdest: account number that this account has voted to be donated the inflation funds
    homedomain:  a value that can be set to be a nickname or an email or web address to ID the account
    thresholds: the value that this accounts thresholds are set that is in xdr base64 code
    flags:  ??
    lastmodified:  stellar sequence code of last changes made on this account

example return:
{"accountid":"GDM6RBPBTDY3YE35I7LLU53LP4IZH26PIFE5IFPITGCEOZBX66IFZIDH","balance":999999960,"seqnum":430244053909506,"numsubentries":2,"inflationdest":null,"homedomain":"test7436","thresholds":"AQADAw==","flags":0,"lastmodified":120119}

#get_lines_balance:
  Values sent:
    account: stellar address base 32 example GCYFPRSLBKM...
    issuer: stellar address of the issuer of the asset in this balance 
    asset:  asset name in this balance example USD, YEN, BEER...

  Values returned: 
    balance: float number of asset balance
    issuer:
    asset: 

example return:
{"issuer":"GC3IIU5Q2WLRC4B7T4GYBJ2UKOQ67RITKTVHCKC6UPECI6RT6JMDUPJO", "asset":"CHP", "balance":105.12}

#get_sell_offers: look up all sell offers made with this issuer and with this asset name
  Values sent:
    issuer: stellar address of the issuer of the asset in this search
    asset: example USD
    limit: limit of the number of offers listed in the stellar-core database max is 10
  Values returned:
    TBD

#get_buy_offers: look up all buy offers made with this issuer and with this asset name
  Values sent:
    issuer: stellar address of the issuer of the asset in this search
    asset: example USD
    limit: limit of the number of offers listed in the stellar-core database max is 10
  Values returned:
    TBD

#version: return the version git hash of stellar-utility and the stellar-core that it is operating
  Values sent:
    no values needed
  
  Values returned:
    status: returns "success" if mss-server is working correctly
    version: values of the git hash for stellar_utility package and git hash for the stellar-core that it is controling if available

 example return:
 {"status":"success", "version":"su: 0.1.0  mss_version: 5063c84d core_version: 85472c7"}


#send_b64: send an envelope blob to the stellar-core network
  Values sent:
    envelope_b64: the envelope blob to be sent that is in xdr base 64 format, this can be any transaction that the signer of the envelope has authority to do

  Value returned:
    TBD
  


#to install and setup
need to add here the dependancies required to run this on Linux Ubuntu or Linux Mint 17 system
They should match what is needed for stellar-utility
TBD

download or clone stellar-utility from github

cd ./multi-sign-server

bundle install

to run:
bundle exec multi-sign-server.rb

Note: before you run you may need to make some changes to the config file

##  Config file settings explained

default example config file:

db_file_path: /home/sacarlson/github/stellar/stellar_utility/stellar-db2/stellar.db
url_horizon: https://horizon-testnet.stellar.org
url_stellar_core: http://localhost:8080
url_mss_server: "localhost:9494"
mode: localcore
fee: 10
start_balance: 100
default_network: Stellar::Networks::TESTNET
master_keypair: Stellar::KeyPair.master
mss_bind: '0.0.0.0'
mss_port: 9494
mss_db_mode: "sqlite"
mss_db_file_path: "./multisign.db"
version: "5063c84d"
core_version: "85472c7"

many of the values in the default config settings will work for most but some settings need to be customized
values explained

db_file_path: points this to the sqlite database that the local stellar-core is now using on this system
              This setting is only needed if mode is set to "localcore" mode.  in "horizon" mode this value is not used
              only sqlite format is supported at this time, postgress can be added later.

url_horizon: this is the URL of the horizon API instance, this is only needed if you are running in the "horizon" mode
             by default it it set to the horizon testnet setting but can later be pointed to the live network if desired

url_stellar_core: This is the URL or IP address and port that you have the local or even a remote stellar-core running on
                  it is normaly run on the local system so localhost should work but the port can be changed and my settings here are not default to stellers release

url_mss_server:  This is the URL and port that the mulit-sign-server will be set to be listening on to recieve action commands

fee: is the fee settings that are used in ruby-stellar-base for transaction fee's, the default in most cases is 10 

start_balance:  is the value in native stellar that will be funded to a newly created stellar account when the create_account function is called

default_network:  defines weather the system will be using the stellar testnet or the stellar live network or maybe some third party network
                  it is defaulted to the testnet setting 

master_keypair: this is the account used to fund new accounts when they are created.  it defaults to the master key that on testnet is 
                like the friendbot that provides free testnet native to play with.  on a live net you would set this to an account that 
                has the needed funding to allow account creation only if needed.

mss_bind:  This is the bind address setting for the mss-server.  it determines the listen address of the server that by default is set to 
           all connected networks on the local system.  it can be set to only listen to itself with localhost setting or only on a sigle nic
           on the system.

mss_port:  this is the port that the multi-sign-server will be listening on the networks for action commands

mss_db_mode: this is the setting of the type of database backend used in the mss-server, at this time only the sqlite is tested
             but support for postgress has already also been partly setup but not debuged and tested yet. advise only using sqlite at this time

mss_db_file_path: this is the sqlite database file path used in the multi-sign-server. be sure the location is read writable under the user you are
                  running the system under.

version:  this is the version stellar-utility git hash number displayed when the "version" action command asks for it.  it should be set to the git
          hash first 8 letters of the stellar-utility you are now using to run mss-server. 

core_version: this is the stellar-core git hash first 8 letters that this system is controling if running in localcore mode
