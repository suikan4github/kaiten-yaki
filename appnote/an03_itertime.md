# AN03 The ITERTIME parameter and vulnerability
The ITERTIME configuration parameter in the config.sh can provide a better user experience during the passphrase input. It can reduce the pain of the longer passphrase and encourage users to use longer passphrases. 

On the other hand, it may pull a vulnerability.

The followings are the consideration around the ITERTIME parameter.

## The passphrase experience
Let's assume there is a Ubuntu desktop system in which the disk was encrypted by Ubiquity installer without Kaiten-yaki. In this system, the /boot partition is installed as a separate and un-encrypted state. So, the Linux kernel file is not protected. 

If the user mistyped the passphrase at boot, Ubuntu prompts to type a passphrase again. There is no pain. It just asks. 

Now, what's happen if a user mistyped the passphrase on the Kaiten-yaki installed system. It takes a very wrong time to see the error message. And the system doesn't prompt to type again ( The prompt issue is discussed in the [AN01](an01_howtorecover.md) ). Especially, the more number of the installations in a system makes the longer duration till the error message. Sometimes this is unbearable pain to the user. 

This kind of pain de-motivates users to use a long passphrase, because the longer passphrase causes more mistypes. As a result, some users may use the shorter passphrase. The bad user experience of passphrase input may help the malicious attackers.

## Why the full disk encryption is so slow at passphrase input
GRUB is the root cause of this slow user passphrase matching. 

The passphrase is hashed and stored to LUKS key slot when a LUKS volume is created ( or, a new passphrase is added ). The stored hash value is not simple. The cryptsetup command makes hash value from the user passphrase. And then, create the next hash from this hash. And then, create a third hash from the 2nd hash, so on. This repeating is named [key stretching](https://en.wikipedia.org/wiki/Key_stretching). 

The key stretching technique enforces malicious attackers using more computation resources on the brute force attacking. The more stretching iteration times require the more resources to attack. 

Of course, there is a balance and security strength. By default, the cryptsetup command takes the iteration needing 1 sect to calculate the passphrase hash, for the LUKS1 format. This sounds like a good balance. The cryptsetup runs on Linux when it calculates the appropriate iteration of key stretching. So, there is no problem if Linux challenges user passwords. It will take about 1 sec, by default. 

But there is a pitfall. On the full disk encryption system by Kaiten-yaki, the /boot is encrypted. So, to load the Linux kernel, GRUB has to decrypt the LUKS volume. That means GRUB has to calculate the passphrase hash. Unfortunately, this calculation is slower than Linux's one. Thus the user has to wait longer than 1 second.

The duration by GRUB is up to the system. It depends on the CPU. Also, In addition to this slow hashing, GRUB has to scan all used key slots when the user mistyped. For example, if 3 distributions are installed in a LUKS volume by Kaiten-yaki, 4 key slots are used. Thus, if it takes 10 seconds to challenged one hash by GRUB, this system takes 40seconds to show "The wrong password". 

This is the mechanism of the slow response at the passphrase input. 
## The key stretching, the --iter-time parameter, and the vulnerability
Kaiten-yaki can relax this pain by ITERTIME configuration parameter in config.sh. This parameter is passed to the cryptsetup command as --iter-time parameter. 

By setting 1000 to the ITERTIME, cryptsetup takes the key stretching iteration cycle to take 1000 milliseconds.  By setting 100, it will be 100 milliseconds. It is believed the default value of --iter-time is 1000 ( Its compile default ). Thus, choosing 100 as ITERTIME makes the duration to the "Wrong password" 4 seconds, in the above example. This sounds acceptable. 

On the other hand, the smaller ITERTIME is the weaker to the bute force attack. It is assumed the strength of the passphrase hash is linear to the ITERTIME parameter ( --iter-time parameter of cryptsetup ).

## The longer passphrase vs. longer key stretching
While the passphrase hash strength is considered linear to the key stretching iteration, the passphrase strength is exponential to its length. 

There many discussions on the strength of the passphrase. Simply speaking, Adding one alphabet ( a-z ) may expand its strength 26 times. That is why the long passphrase is very important. 

The 1/10 strength of the key stretching can be covered by adding 1 character to the passphrase. 

## Conclusion
The full disk encryption will give big pain to the user at the passphrase input phase. It seems to be reasonable to use the smaller ITERTIME ( --iter-time ) parameter to encourage the user to use the longer passphrase like 20 letters, from the viewpoint of security. 

The security policy is up to the people, community, and mission. The consideration here assumed the desktop PC as a hobby. For mission-critical usage, the user should consult security experts. 