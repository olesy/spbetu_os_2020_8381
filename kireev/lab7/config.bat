del ovrl1.ovl
del ovrl2.ovl
masm ovrl1.asm;
link ovrl1.obj;
exe2bin ovrl1.exe ovrl1.com
ren ovrl1.com ovrl1.ovl
masm ovrl2.asm;
link ovrl2.obj;
exe2bin ovrl2.exe ovrl2.com
ren ovrl2.com ovrl2.ovl
masm os7.asm;
link os7.obj;
os7.exe