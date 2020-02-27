KVM_AutoBoot - Boots your KVM's virtual machines at your server's boot
=============

What is KVM_AutoBoot?
-----

<img border="0" alt="KVM_AutoBoot" src="./resrc/kvm_autoboot.jpg" height="20%" width="20%"/>KVM_AutoBoot

The KVM_AutoBoot is a service (bash script) that boots your KVM's VMs (virtual machines) at your server's boot.

Currently KVM_AutoBoot is only compatible with CentOS 7, however adjusting it to work with other distros will be simple.

**NOTE:** The KVM_AutoBoot uses libvirt.

Install KVM_AutoBoot on CentOS 7 (example/demo)
-----

Download and start the KVM_AutoBoot installer...

```
yum -y install git-core
cd /usr/local/src
git clone https://github.com/eduardolucioac/kvm_autoboot.git
cd /usr/local/src/kvm_autoboot
bash install.bash
```

In the excerpt...

```
[ NAVIGATE: ↓ down arrow | ↑ up arrow | ⇟ page down | ⇞ page up | ↕ mouse wheel ]
[ CONTINUE: q ]
> ------------------------------------------------
KVM_AutoBoot Installer (0.0.1.0)
----------------------------------

  > ABOUT:

    This script will install KVM_AutoBoot!
    
      .~.  Have fun! =D
      /V\  
     // \\ Tux
    /(   )\
     ^`~'^ 

  > WARNINGS:

    - This installer is compatible with Centos 7.
[...]
```

... read the introductions and proceed by pressing "q".

In the excerpt...

```
[ NAVIGATE: ↓ down arrow | ↑ up arrow | ⇟ page down | ⇞ page up | ↕ mouse wheel ]
[ CONTINUE: q ]
> ------------------------------------------------
LICENSE/TERMS:
----------------------------------

  BSD 3-Clause License
  
  Copyright (c) 2019, Eduardo Lúcio Amorim Costa
  All rights reserved.
  
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  
  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions and the following disclaimer.
  
  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
[...]
```

... read the license (BSD 3-Clause License) and proceed by pressing "q".

In the excerpt...

```
[...]
----------------------------------
BY ANSWERING YES (y) YOU WILL AGREE WITH TERMS AND CONDITIONS PRESENTED! PROCEED? (y/n) 
[...]
```

... inform that you read and accepted the license by pressing "y" (if you agree with the license, of course).

In the excerpt...

```
> ------------------------------------------------
INSTRUCTIONS:
----------------------------------

  The KVM_AutoBoot is a service that starts your KVM's VMs (Virtual Machines) at the boot of your server.
  
  The KVM_AutoBoot's service is started during server boot after the libvirt's service ("libvirtd.service") starts.
  
  After starting all the VMs defined in the BOOT_ORDER list - configuration file "/usr/local/kvm_autoboot/conf/conf.bash" - respecting the start interval defined for each one, the KVM_AutoBoot's service ends. If there are no VMs defined in the BOOT_ORDER list, the KVM_AutoBoot's service stops immediately.
  
  To cancel installation at any time use Ctrl+c.

< ------------------------------------------------
Press enter to continue...
```

... read the instructions and proceed by pressing "q".

In the excerpt...

```
[...]
----------------------------------
Install KVM_AutoBoot? (y/n) 
```

... enter "y" to start the installation.

In the excerpt...

```
[ NAVIGATE: ↓ down arrow | ↑ up arrow | ⇟ page down | ⇞ page up | ↕ mouse wheel ]
[ CONTINUE: q ]
> ------------------------------------------------
Installer finished! Thanks!
----------------------------------

  > USEFUL INFORMATION:

    To configure KVM_AutoBoot...
        vi /usr/local/kvm_autoboot/conf/conf.bash
    
    Installation Log...
        vi /usr/local/src/kvm_autoboot/installation.log
    
    KVM_AutoBoot's executable bash script...
        /usr/local/kvm_autoboot/kvm_autoboot.bash
    
    KVM_AutoBoot's service logs...
        /var/log/kvm_autoboot/*
```

... press "q" and the installation will be complete.

**Configure KVM_AutoBoot**
  
Open the configuration file...

```
vi /usr/local/kvm_autoboot/conf/conf.bash
```

... and in the BOOT_ORDER parameter inform which VMs (virtual machines) should be booted at server boot...

```
BOOT_ORDER=("VM_NAME0" CUSTOM_INTERV1 "VM_NAME1" CUSTOM_INTERV2 "VM_NAME2")
```

NOTE: The BOOT_ORDER list - actually a bash "array" - should contain the names of the VMs in the desired boot order and the interval to be used before each VM in the sequence (in seconds). The first VM in the list will be initialized with the service and the others after the interval defined immediately before their name. If the interval is set to "-1", the default interval (BOOT_DEF_INTERV) will be used.

To test, **if you want**, start the KVM_AutoBoot service with the command...

```
systemctl start kvm_autoboot.service
```

... that will get the service started.

**NOTE:** The service will stop after starting all the VMs in the BOOT_ORDER list.

**TIPS:**

 I - To list the KVM's virtual machines names...

`
virsh list --all
`;

 II - To check the KVM_AutoBoot's service status...

`
systemctl status kvm_autoboot.service
`;

 III - To track the last KVM_AutoBoot's execution log...

`
cd /var/log/kvm_autoboot/ && less +F $(ls -Art | tail -n 1)
`.

About
-----

KVM_AutoBoot 🄯 BSD-3-Clause  
Eduardo Lúcio Amorim Costa  
Brazil-DF

<img border="0" alt="Brazil-DF" src="http://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Map_of_Brazil_with_flag.svg/180px-Map_of_Brazil_with_flag.svg.png" height="15%" width="15%"/>
