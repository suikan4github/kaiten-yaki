# Managing LUKS key slots
If somebody want to install two or three distributions into a system, Kaiten-yaki works perfectly. There is not problem at all. 

On the other hand, some extreme cases like installing distributions as many as possible, or repeating the overwrite installation, the user must understand and manage the LUKS key slots well. 

This application note explains the limitations and difficulties by the number of LUKS key slots, and how to overcome that limitation( if possible ).

# The LUKS key slots
The LUKS volume has 8 key slots. That means, up to 8 key hashes can be stored. In other words, user can use 8 different keys to open a LUKS volume. 

In this case, the "user" is not limited as human being. Any software can use passphrase to open a LUKS volume. Thus, even the "user" is one person, multiple key slot may be used.

If some user ( or software ) feed the passpharse to open a LUKS, the management software ( dm-crypt library ) scans keyslots and check whether there is a macching slot or not. If there is a slot which stored hash value maches with the hash value of the given passphrase, that passphrase is the right one.  

# Usage of key slots by Kaiten-yaki
Kaiten-yaki N+1 LUKS key slots to install the N distributions in a system. 

Whenever Kaiten-yaki create a LUKS volume, it registers the passphrase typed by the user. This passphrase is stored in to the key slot 0. So, when user type his passphrase correctly, it will be matched with the has value in the slot 0, by default. 

In addition to the user passphrase, Kaiten-yaki uses one key slot to register the passphrase to open the LUKS volume from the linux kernel. This passphrase is different from the 

# Overwrite installation 

# Managing key slots


# A dirty hack

