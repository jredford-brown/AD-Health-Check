First things first, run AD Health Check Script.ps1 in this directory, once done you'll have a txt file that publishes your results.
We'll run through each section.

Server Configuration - All of the domain controllers in the forest will appear here, it'll show hostname domain and interface index, thats informational, what we're interested in is DNSAddresses and Forwarders.
What you should be seeing here is DNS Addresses having the partner domain controller IP as its primary, then the loopback IP as the secondary. 
You MUST have your primary IP as a domain controller in your domain, NOT your forest. (If you're a mad man with a single DC in a domain use a loopback, DNS forwarders are king)
You MUST NOT have the loopback address as the primary, in that case when the DNS role restarts or after a reboot you will have degraded DNS resolutions or in some cases no DNS resolution.
Forwarders are what your DNS role on each DC will forward requests it cannot resolve too, if this is a child domain in a forest, point it to the root domain controllers, if its a root domain point it to your DNS solution or to your fave internet DNS provider.

NTP Configuration - If your DC that you've run this from is a GC, dont let this be NT5DS, that means it takes time from the holder of FSMO role PDCEmulator. If the role ever fails over to this DC time will likely skew across the domain.

DCDIAG Section - DNS Test, Machine Account Test, Services Test, NetLogons Test, Replications Test and FSMO Check Test, these are your basic checks on the health of your domain, honestly if you're seeing stuff here you'll likely be suffering so I feel for you.
DNS Test, so this one checks your root DNS zone health as well as _msdcs zone health, your SRV records and NS records, the stuff that keeps it all running.
Machine Account Test, don't take your domain controllers out of the default OU, put it back in that OU before I come over there.
Services Test, checks AD related services on each domain controller
NetLogons Test, this is your SYSVOL NETLOGON folders, you have DFSR problems if you see this, try to perform a authoritive replication from the FSMO holder
Replications Test, this'll probably be down to a misconfigured DNS or firewalls blocking your peace
FSMO Check Test, we want everyone to know whos the boss, the big GC, this one complains in split brain scenarios but I've never seen it happen

NS Records - My fave section, this bit will recursively go through all your zones and check it can reach the NS records specified, keep an eye out here to make sure that
a) The NS records are timing out, either firewall problems or old DCs that werent decommed properly
b) All the records that you expect to be responsible for a zone are there
How do you fix it? Firstly run a 'ipconfig /registerdns', this should create records that should already be there, honestly if you're seeing some odd things round here your first action is run that command on all of the DCs.
Next, load up the DNS console, go zone by zone making sure the DCs are all here also making sure to right click, properties, name servers and checking they're here.

Forwarder Response Time - This creates an array of all your forwarders on this DC and queries them to see how long it take to give you a record, it creates an average not just a single lookup.

Test Port Access - I've been done in by bad firewall ports before so this is my check, as well as seeing whats actually listening on these DCs.

Replication Status - If you're domain is broken lookout for unsuccessful replications and to which DC, that'll likely either be the bad DC or what to look for in DNS. If you're looking here for health checks make sure the interval is what you want it to be (link below),  make sure queues arent too bad, check each domain controller has the right replication links, KCC/ISTG will determine this for you but you'll be able to see in sites and services if someone got thier dirty hands on it.
https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/determining-the-interval

LDAP Configuration - Little bit for fun, tells you if LDAPS is enabled and when the certificate expires, if you're seeing issues here then likely to do with certificate, make sure all your DCs have this certificate in the same place, check the Personal certificate store 
of the ADDS service account as it'll use this store first then it'll use the personal local computer store. Recheck the template the certificate was generated from if you use a CA on domain for your LDAPS, perhaps make it auto renew?

Thats it, hope you had fun, any suggestions please make them, any ammendments please suggest them. If it helped let me know? - JRB