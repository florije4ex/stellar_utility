# stellar_utility
a set of examples to setup transactions on the new stellar-core and a small utility lib that I setup and used to learn with 

The examples here are meant to be run when you are running a local standalone stellar-core on your system.
you must at least have the url_stellar_core value correct in the stellar_utilities.cfg file
see ./stellar-db/ and run start_core.sh  or if that fails after first install or any upgrade pulls for stellar-core try reset_core.sh

note: this was write in my attempts to learn how to use ruby-stellar-base.  I think later I will find
that stellar_core_commander is a better path to start to learn and test stellar-core features with after we figure it out how to configure and use it with a localy hosted stellar-core.  Much of the code in the stellar_utilities.rb was pulled and ported from what I found in stellar_core_commander sections.  I think in the future I will use the stellar_core_commander libs directly to do my new functions and coding. maybe I'll port or repackage a stellar_core_commander_lite edition where not all the fancy stuff is needed to be mostly used to integrate into other aplications.  I would also like to add a way to not only point controls to a localhosted stellar-core or docker core, but also send transactions through to the horizon website api interface.  When I get that all figured out maybe I'll also add it to this repository as a reference for others to learn from.
