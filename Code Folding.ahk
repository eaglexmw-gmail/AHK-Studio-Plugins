﻿#SingleInstance,Force
;menu Toggle Current Fold
;menu Toggle All Folds,foldall
x:=ComObjActive("AHK-Studio"),sc:=x.sc()
if ((info:=%true%)="foldall")
	sc.2662(2)
else
	sc.2237(sc.2166(sc.2008),2)
ExitApp