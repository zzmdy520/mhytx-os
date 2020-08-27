# readme

这是<还原操作系统真象>一书的学习记录。

关于第一章部署工作环境,在macos catalina下可以使用我的配置方法。

## bochs配置文件

1.Macos平台下使用`brew install bochs`安装bochs。

brew安装后为bochs最新版本2.6.11。其他版本不保证可以正确运行至第一章最后的效果。

尝试使用作者书中的配置方法以及参考博文[1]都无法在macos系统下2.6.11版本正确运行。

于是在bochs中进行文件配置。

这里参考了 x86汇编语言:从实模式到保护模式 配置方法。

## 创建虚拟硬盘

terminal输入bximage

```
=================================================================
                                bximage
  Disk Image Creation / Conversion / Resize and Commit Tool for Bochs
         $Id: bximage.cc 13481 2018-03-30 21:04:04Z vruppert $
==================================================================

1. Create new floppy or hard disk image
2. Convert hard disk image to other format (mode)
3. Resize hard disk image
4. Commit 'undoable' redolog to base image
5. Disk image info

0. Quit
```

操作如下:

```
Please choose one [0] 1

Create image

Do you want to create a floppy disk image or a hard disk image?
Please type hd or fd. [hd]

What kind of image should I create?
Please type flat, sparse, growing, vpc or vmware4. [flat]

Choose the size of hard disk sectors.
Please type 512, 1024 or 4096. [512]

Enter the hard disk size in megabytes, between 10 and 8257535
[10] 60

What should be the name of the image?
[c.img] hd60M.img

Creating hard disk image 'hd60M.img' with CHS=121/16/63 (sector size = 512)

The following line should appear in your bochsrc:
  ata0-master: type=disk, path="hd60M.img", mode=flat
```

记住 CHS=121/16/63 ，之后配置要用。

文件创建后的位置不固定(我也不知为何有时候生成/Users/你的账号/中，有时候又在bochs目录里）。 所以创建后搜索一下文件名看下在哪。

## 配置文件

- terminal输入bochs

```
You can also start bochs with the -q option to skip these menus.

1. Restore factory default configuration
2. Read options from...
3. Edit options
4. Save options to...
5. Restore the Bochs state from...
6. Begin simulation
7. Quit now
```

- 输入3。

```
------------------
Bochs Options Menu
------------------
0. Return to previous menu
1. Optional plugin control
2. Logfile options
3. Log options for all devices
4. Log options for individual devices
5. CPU options
6. CPUID options
7. Memory options
8. Clock & CMOS options
9. PCI options
10. Bochs Display & Interface options
11. Keyboard & Mouse options
12. Disk & Boot options
13. Serial / Parallel / USB options
14. Network card options
15. Sound card options
16. Other options
17. User-defined options
```

- 输入12。

```
------------------
Bochs Disk Options
------------------
0. Return to previous menu
1. First Floppy Drive
2. Second Floppy Drive
3. ATA channel 0
4. First HD/CD on channel 0
5. Second HD/CD on channel 0
6. ATA channel 1
7. First HD/CD on channel 1
8. Second HD/CD on channel 1
9. ATA channel 2
10. First HD/CD on channel 2 (disabled)
11. Second HD/CD on channel 2 (disabled)
12. ATA channel 3
13. First HD/CD on channel 3 (disabled)
14. Second HD/CD on channel 3 (disabled)
15. Boot Options
```

- 输入4。

```
Enter type of ATA device, disk or cdrom: [disk]
Enter new filename: [/Users/你的账号/hd60M.img]
Enter mode of ATA device, (flat, concat, etc.): [flat]
Enter number of cylinders: [121]
Enter number of heads: [16]
Enter number of sectors per track: [63]
Enter sector size: [512]
Enter new model name: [Generic 1234]
Enter bios detection type: [cmos]
Enter translation type: [auto]
```

- 返回上一级选择15 boot options。

设置为:

```
0. Return to previous menu
1. Boot drive #1: disk
2. Boot drive #2: none
3. Boot drive #3: none
4. Skip Floppy Boot Signature Check: yes
```

- 返回选择7 memory options。

- 选择1  一路回车。

- 最后返回顶级菜单。选择4 save options to...保存到bochsrc.txt

  然后打开bochsrc.txt

  找到`romimage: file`将 `address=...`等内容去掉。

  问题原因：*参考资料[2]]*
  在2.3.5以前的bochs使用的BIOS-bochs-latest是64k的，那个时候需要加上
  romimage: file=BIOS-bochs-latest,address=0xf0000
  在2.3.5中的BIOS-bochs-latest更新了，变成了128k的，这个时候配置需要改为
  romimage: file=$BXSHARE/BIOS-bochs-latest

Nasm 编译:

`nasm -Iinclude/  -o loader.bin loader.S `

dd写入虚拟硬盘:

`dd if=/Users/lonekriss/Desktop/mememe/操作系统/mbr/loader.bin  of=/Users/lonekriss/hd60m.img bs=512 count=1 seek=2 conv=notrunc`

参考资料:

参考资料1:http://imushan.com/2018/07/11/os/Bochs%E5%AD%A6%E4%B9%A0-%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE%E7%AF%87/

[参考资料[2]](https://www.it610.com/article/5523805.htm)

