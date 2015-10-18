#SingleInstance,Force
;menu Github Repository
#NoTrayIcon
#NoEnv
#SingleInstance,Force
x:=Studio(),x.save()
global settings,git,vversion,node,newwin,v,win,ControlList:={owner:"Owner (GitHub Username)",email:"Email",name:"Your Full Name",token:"API Token"},new,files,dxml
win:="Github_Repository",vversion:=x.get("vversion"),settings:=x.get("settings"),newwin:=new GUIKeep(win),files:=x.get("files")
Hotkey,IfWinActive,% newwin.id
for a,b in {"^Down":"Arrows","RButton":"RButton","^Up":"Arrows","~Delete":"Delete","F1":"compilever","F2":"clearver","F3":"wholelist"}
	Hotkey,%a%,%b%,On
newwin.add("Text,Section,Versions:","Text,x162 ys,Branches:","TreeView,xm w160 h120 gtv AltSubmit section","Treeview,x162 ys w198 h120,,w","Text,xm,Version &Information:","Edit,w360 h200 gedit vedit,,wh","ListView,w145 h200 geditgr AltSubmit NoSortHdr,Github Setting|Value,wy","ListView,x+0 w215 h200,Additional Files|Directory,xy","Button,xm gUpdate,&Update Release Info,y","Button,x+5 gcommit,Co&mmit,y","Button,x+5 gDelRep,Delete Repository,y","Button,xm gatf Default,&Add Text Files,y","Button,x+5 ghelp,&Help,y","Button,x+5 gRefreshBranch,&Refresh Branch,y","Radio,xm,&Full Release,y","Radio,x+2 vprerelease Checked,&Pre-Release,y","Radio,x+2 vdraft,&Draft,y","Checkbox,xm vonefile gonefile " (check:=ssn(node(),"@onefile").text?"Checked":"") " ,Commit As &One File,y","StatusBar")
git:=new Github(),SB_SetText("Remaining API Calls: Will update when you make a call to the API"),PopVer(),PopBranch()
newwin.show("Github Repository")
node:=dxml.ssn("//branch[@name='" git.branch "']")
if(sn(node,"*[@sha]").length!=sn(node,"*").length)
	git.treesha()
return
Github_RepositoryClose:
Github_RepositoryEscape:
Default("TreeView","SysTreeView322")
TV_GetText(branch,TV_GetSelection()),node().SetAttribute("branch",branch),newwin.exit()
WinClose,% newwin.id
ExitApp
Add(vers){
	if(nn:=ssn(node:=node(),"descendant::version[@number='" vers "']"))
		return nn
	list:=sn(node,"versions/version"),root:=ssn(node,"versions"),newnode:=vversion.under(root,"version"),newnode.SetAttribute("number",vers)
	while,ll:=list.item[A_Index-1],ea:=xml.ea(ll){
		if(vers>ea.number){
			root.insertbefore(newnode,ll),PopVer()
			Break
	}}
	return node
}
Arrows(){
	default(),TV_GetText(vers,TV_GetSelection()),ver:=StrSplit(vers,"."),version:="",current:=ssn(node(),"descendant::version[@number='" vers "']"),last:=ver[ver.MaxIndex()]
	for a,b in ver
		if(a!=ver.MaxIndex())
			build.=b "."
	if(A_ThisHotkey="^Up"){
		if(next:=current.previoussibling)
			return TV_Modify(next.SelectSingleNode("@tv").text,"Select Vis Focus")
		build.=last+1,parent:=current.ParentNode,new:=vversion.under(parent,"version"),new.SetAttribute("number",build),new.SetAttribute("select",1),parent.InsertBefore(new,current),PopVer()
	}else{
		if(next:=current.nextsibling)
			return TV_Modify(next.SelectSingleNode("@tv").text,"Select Vis Focus")
		if(last-1<0)
			return m("Minor versions can not go below 0","Right Click to change the major version")
		build.=last-1,parent:=current.ParentNode,new:=vversion.under(parent,"version"),new.SetAttribute("number",build),new.SetAttribute("select",1),PopVer()
}}
atf(){
	global x
	main:=x.current(2).file
	SplitPath,main,,dir
	FileSelectFile,file,M,%dir%,Select A File to Add To This Repo Upload,*.ahk;*.xml
	if(ErrorLevel)
		return
	if(!extra:=ssn(node(),"files"))
		extra:=vversion.under(node(),"files")
	for a,b in StrSplit(file,"`n","`n"){
		if(A_Index=1)
			start:=b
		else if(!ssn(extra,"file[text()='" start "\" b "']"))
			vversion.under(extra,"file","",start "\" b)
	}PopVer()
}
Class Github{
	static url:="https://api.github.com",http:=[]
	__New(){
		ea:=settings.ea("//github")
		if(!(ea.owner&&ea.token))
			return m("Please setup your Github info")
		this.http:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
		if(proxy:=settings.ssn("//proxy").text)
			http.setProxy(2,proxy)
		for a,b in ea:=ea(settings.ssn("//github"))
			this[a]:=b
		this.repo:=ssn(node(),"@repo").text,this.token:="?access_token=" ea.token,this.owner:=ea.owner,this.tok:="&access_token=" ea.token,this.repo:=ssn(node(),"@repo").text,this.baseurl:=this.url "/repos/" this.owner "/" this.repo "/",this.refresh()
		return this
	}
	json(info){
		for a,b in info
			json.=chr(34) a Chr(34) ":" (b="true"||b=1?"true":b=""||b="false"||b="0"?"false":Chr(34) b Chr(34)) ","
		return "{" Trim(json,",") "}"
	}
	repourl(){
		return this.url "/repos/" this.owner "/" this.repo "/"
	}
	treesha(){
		node:=dxml.ssn("//branch[@name='" this.branch "']"),url:=this.url "/repos/" this.owner "/" this.repo "/commits/" this.branch this.token,tree:=this.sha(this.Send("GET",url)),url:=this.url "/repos/" this.owner "/" this.repo "/git/trees/" tree this.token "&recursive=1",info:=this.Send("GET",url),info:=SubStr(info,InStr(info,"tree" Chr(34)))
		for a,b in StrSplit(info,"{")
			if(path:=this.find("path",b)){
				if(this.find("mode",b)!="100644"||path="readme.md")
					Continue
				StringReplace,path,path,/,\,All
				if(!nn:=ssn(node,"descendant::*[@file='" path "']"))
					nn:=dxml.under(node,"file",{file:path})
				nn.SetAttribute("sha",this.find("sha",b))
			}dxml.save(1)
	}
	delete(filenames){
		if(sn(node,"*[@sha]").length!=sn(node,"*").length)
			this.treesha()
		node:=dxml.ssn("//branch[@name='" this.branch "']")
		for c,d in filenames{
			StringReplace,cc,c,\,/,All
			url:=this.url "/repos/" this.owner "/" this.repo "/contents/" cc this.token,sha:=ssn(node,"descendant::*[@file='" c "']/@sha").text
			if(!sha)
				Continue
			this.http.Open("DELETE",url),this.http.send(this.json({"message":"Deleted","sha":sha,"branch":this.branch}))
			if(this.http.status!=200){
				m("Error deleting " c,this.http.ResponseText,"Will try again next commit"),this.treesha()
				Continue
			}d.ParentNode.RemoveChild(d)
	}}
	refresh(){
		global x
		if(this.repo)
			dxml:=new XML("repo",x.path() "\github\" this.repo ".xml"),branch:=ssn(node(),"@branch").text,this.branch:=branch?branch:"master"
	}
	find(search,text){
		RegExMatch(text,"U)" Chr(34) search Chr(34) ":(.*),",found)
		return Trim(found1,Chr(34))
	}
	sha(text){
		RegExMatch(this.http.ResponseText,"U)" Chr(34) "sha" Chr(34) ":(.*),",found)
		return Trim(found1,Chr(34))
	}
	gettree(value:=""){
		info:=this.send("GET",this.url "/repos/" this.owner "/" this.repo "/git/trees/" this.getref() this.token)
		if(value){
			temp:=new xml("tree")
			top:=temp.ssn("//tree")
			info:=SubStr(info,InStr(info,Chr(34) "tree" Chr(34))),pos:=1
			while,RegExMatch(info,"OU){(.*)}",found,pos){
				new:=temp.under(top,"node")
				for a,b in StrSplit(found.1,",")
					in:=StrSplit(b,":",Chr(34)),new.SetAttribute(in.1,in.2)
				pos:=found.pos(1)+found.len(1)
			}
			temp.Transform(2)
		}
		return temp
	}
	getref(){
		url:=this.url "/repos/" this.owner "/" this.repo "/git/refs/heads/" this.branch this.token
		this.cmtsha:=this.sha(this.Send("GET",url))
		RegExMatch(this.Send("GET",this.url "/repos/" this.owner "/" this.repo "/commits/" this.cmtsha this.token),"U)tree.:\{.sha.:.(.*)" Chr(34),found)
		return found1
	}
	blob(repo,text,skip:=""){
		url:=this.url "/repos/" this.owner "/" repo "/git/blobs" this.token
		if(!skip)
			text:=encode(text)
		json={"content":"%text%","encoding":"base64"}
		return this.sha(this.Send("POST",url,json))
	}
	send(verb,url,data=""){
		this.http.Open(verb,url),this.http.send(data),SB_SetText("Remaining API Calls: " this.remain:=this.http.GetResponseHeader("X-RateLimit-Remaining"))
		return this.http.ResponseText
	}
	tree(repo,parent,blobs){
		url:=this.url "/repos/" this.owner "/" repo "/git/trees" this.token,open:="{"
		if(parent)
			json=%open%"base_tree":"%parent%","tree":[
		else
			json=%open%"tree":[
		for a,blob in blobs{
			add={"path":"%a%","mode":"100644","type":"blob","sha":"%blob%"},
			json.=add
		}
		return this.sha(this.Send("POST",url,Trim(json,",") "]}"))
	}
	commit(repo,tree,parent,message="Updated the file",name="placeholder",email="placeholder@gmail.com"){
		message:=this.utf8(message),parent:=this.cmtsha,url:=this.url "/repos/" this.owner "/" repo "/git/commits" this.token
		json={"message":"%message%","author":{"name": "%name%","email": "%email%"},"parents":["%parent%"],"tree":"%tree%"}
		return this.sha(this.Send("POST",url,json))
	}
	ref(repo,sha){
		url:=this.url "/repos/" this.owner "/" repo "/git/refs/heads/" this.branch this.token,this.http.Open("PATCH",url)
		json={"sha":"%sha%","force":true}
		this.http.send(json)
		SplashTextOff
		return this.http.status
	}
	Limit(){
		url:=this.url "/rate_limit" this.token,this.http.Open("GET",url),this.http.Send()
		m(this.http.ResponseText)
	}
	CreateRepo(name,description="",homepage="",private="false",issues="true",wiki="true",downloads="true"){
		url:=this.url "/user/repos" this.token
		for a,b in {homepage:this.utf8(homepage),description:this.utf8(description)}
			if(b!=""){
				aa="%a%":"%b%",
				add.=aa
			}
		json={"name":"%name%",%add%"private":%private%,"has_issues":%issues%,"has_wiki":%wiki%,"has_downloads":%downloads%,"auto_init":true}
		this.Send("POST",url,json)
	}
	CreateFile(repo,filefullpath,text,commit="First Commit",realname="Testing",email="Testing"){
		SplitPath,filefullpath,filename
		url:=this.url "/repos/" this.owner "/" repo "/contents/" filename this.token,file:=this.utf8(text)
		json={"message":"%commit%","committer":{"name":"%realname%","email":"%email%"},"content": "%file%"}
		this.http.Open("PUT",url),this.http.send(json),RegExMatch(this.http.ResponseText,"U)"Chr(34) "sha" Chr(34) ":(.*),",found)
	}
	utf8(info){
		info:=RegExReplace(info,"([" Chr(34) "\\])","\$1")
		for a,b in {"`n":"\n","`t":"\t","`r":"\r"}
			StringReplace,info,info,%a%,%b%,All
		return info
}}
Commit(){
	/*
		WHEN YOU CREATE A NEW REPO!!!!
		make sure that you check the repo directory so you don't create a duplicate
		also have it tag the xml with the branch.
		if(fileexist("github\" reponame ".xml"))
			return m("Repo already exists.")
	*/
	global settings,x
	info:=newwin[],commitmsg:=info.edit,main:=file:=x.current(2).file,ea:=settings.ea("//github")
	if(!commitmsg)
		return m("Please select a commit message from the list of versions, or enter a commit message in the space provided")
	if(!(ea.name&&ea.email&&ea.token&&ea.owner)){
		SetTimer,ugi,-1
		return
	}
	if(!rep:=vversion.ssn("//*[@file='" file "']"))
		rep:=vversion.Add("info",,,1),rep.SetAttribute("file",file)
	delete:=[],path:=x.path() "\github\" git.repo,current:=x.current(2).file
	if(FileExist(path))
		FileRemoveDir,%path%,1
	if(!FileExist(x.path "\github"))
		FileCreateDir,% x.path() "\Github"
	if(!(git.repo))
		return m("Please setup a repo name in the GUI by clicking Repository Name:")
	main:=files.ssn("//main[@file='" x.current(2).file "']"),temp:=new XML("temp"),temp.xml.loadxml(main.xml)
	Default("TreeView","SysTreeView322")
	TV_GetText(branch,TV_GetSelection())
	Gui,%win%:TreeView,SysTreeView321
	git.branch:=branch,root:=dxml.ssn("//*")
	list:=sn(node(),"files/*")
	if(!top:=dxml.ssn("//branch[@name='" git.branch "']"))
		top:=dxml.under(root,"branch",{name:git.branch})
	while,ll:=list.item[A_Index-1],ea:=xml.ea(ll){
		filename:=StrSplit(ll.text,"\").pop()
		if(!ssn(top,"descendant::file[@fullpath='" ll.text "']"))
			dxml.under(top,"file",{fullpath:ll.text,file:"lib\" filename})
	}
	all:=sn(top,"descendant::file")
	/*
		have it check to see if the file is in the same dir as the project
		if so have it not put the lib\ in front of it
			call it prefix or something or libfolder
	*/
	while,aa:=all.item[A_Index-1],ea:=xml.ea(aa){
		filename:=temp.ssn("//*[@github='" ea.file "']/@file").text
		if(ea.fullpath){
			if(FileExist(ea.fullpath))
				Continue
			delete[ea.file]:=aa
		}else if(filename="")
			delete[ea.file]:=aa,del:=1 ;,aa.ParentNode.RemoveChild(aa)
	}
	if(del)
		git.Delete(delete)
	all:=temp.sn("//main[@file='" x.current(2).file "']/descendant::*[@github!='']"),uplist:=[],onefile:=[]
	if(info.onefile){
		gh:=temp.ssn("//main[@file='" x.current(2).file "']/file/@github").text
		if(info.onefile){
			gh:=temp.ssn("//main[@file='" x.current(2).file "']/file/@github").text
			FileGetTime,time,% ea.file,M
			if(time!=dxml.ssn("//branch[@name='" git.branch "']/*[@file='" ea.github "']/@time").text)
				onefile[ea.github]:=time,up:=1
			if(up){
				FileGetTime,time,% temp.ssn("//main[@file='" x.current(2).file "']/file/@file").text
				uplist[RegExReplace(gh,"\\","/")]:={text:x.publish(1),encoding:ea.encoding,time:time}
			}
		}
	}else{
		while,aa:=all.item[A_Index-1],ea:=xml.ea(aa){ ;updated files
			FileGetTime,time,% ea.file,M
			if(time!=dxml.ssn("//branch[@name='" git.branch "']/*[@file='" ea.github "']/@time").text){
				file1:=FileOpen(ea.file,0,ea.encoding),text:=file1.Read(file1.length),file1.close(),uplist[RegExReplace(ea.github,"\\","/")]:={text:text,encoding:ea.encoding,time:time},up:=1
				if(!node:=dxml.ssn("//branch[@name='" git.branch "']/*[@file='" ea.github "']"))
					node:=dxml.under(top,"file",{file:ea.github})
			}
		}
	}
	while,ll:=list.item[A_Index-1],ea:=xml.ea(ll){
		FileGetTime,time,% ll.text
		filename:=StrSplit(ll.text,"\").pop(),ffp:=ll.text
		if(time!=dxml.ssn("//branch[@name='" git.branch "']/*[@file='lib\" filename "']/@time").text){
			FileRead,bin,% "*c " ffp
			FileGetSize,size,%ffp%
			DllCall("Crypt32.dll\CryptBinaryToStringW",Ptr,&bin,UInt,size,UInt,1,UInt,0,UIntP,Bytes),VarSetCapacity(out,Bytes*2),DllCall("Crypt32.dll\CryptBinaryToStringW",Ptr,&bin,UInt,size,UInt,1,Str,out,UIntP,Bytes)
			StringReplace,out,out,`r`n,,All
			uplist["lib/" filename]:={text:out,encoding:"UTF-8",time:time,skip:1},up:=1
		}
	}
	if(!up)
		return m("Nothing new to upload")
	if(!current_commit:=git.getref()){
		git.CreateRepo(git.repo)
		Sleep,500
		current_commit:=git.getref()
	}
	upload:=[]
	for a,text in uplist{
		newtext:=text.text?text.text:";Blank File",blob:=git.blob(git.repo,RegExReplace(newtext,Chr(59) "github_version",version),text.skip)
		if(!blob){
			SplashTextOff
			return m("Error occured while uploading " text.local)
		}
		WinSetTitle,% newwin.id,,Uploading: %a%
		upload[a]:=blob
	}
	tree:=git.Tree(git.repo,current_commit,upload),commit:=git.commit(git.repo,tree,current_commit,commitmsg,git.name,git.email),info:=git.ref(git.repo,commit)
	if(info=200){
		top:=dxml.ssn("//branch[@name='" git.branch "']")
		for a,b in upload
			ssn(top,"descendant::*[@file='" RegExReplace(a,"\/","\") "']").SetAttribute("sha",b)
		for a,b in uplist
			ssn(top,"descendant::*[@file='" RegExReplace(a,"\/","\") "']").SetAttribute("time",b.time)
		for a,b in onefile
			ssn(top,"descendant::*[@file='" a "']").SetAttribute("time",b)
		dxml.save(1),x.TrayTip("GitHub Update Complete")
	}Else
		m("An Error Occured" ,commit)
	WinSetTitle,% newwin.id,,Github Repository
	up:="",del:=""
}
compilever:
default("TreeView","SysTreeView321"),TV_GetText(ver,TV_GetSelection())
WinGetPos,,,w,,% newwin.ahkid
info:=newwin[],text:=info.edit
vertext:=ver&&text?ver "`r`n" text:""
if(vertext){
	Clipboard.=vertext "`r`n"
	ToolTip,%Clipboard%,%w%,0,2
}else
	m("Add some text")
return
default(info*){
	Gui,%win%:Default
	if(info.1&&info.2)
		Gui,% win ":" info.1,% info.2
}
delete(){
	ControlGetFocus,Focus,% newwin.id
	if(Focus="SysTreeView321"){
		default(),cn:=ssn(node(),"descendant::version[@tv='" TV_GetSelection() "']")
		select:=cn.nextsibling?cn.nextsibling:cn.previoussibling?cn.previoussibling:""
		if(select)
			select.SetAttribute("select",1)
		cn.ParentNode.RemoveChild(cn),PopVer()
	}
}
DelRep(){
	global vversion
	MsgBox,276,Delete This Repository,THIS CAN NOT BE UNDONE! ARE YOU SURE
	IfMsgBox,Yes
	{
		if(git.repo="AHK-Studio")
			return m("NO! you can not.")
		info:=git.send("DELETE",git.url "/repos/" git.owner "/" git.repo git.token)
		if(InStr(git.http.status,204)){
			rem:=vversion.ssn("//info[@file='" ssn(node(),"@file").text "']"),rem.ParentNode.RemoveChild(rem),git.repo:=""
			FileRemoveDir,% A_ScriptDir "\github\" ea.repo,1
		}else
			m("Something went wrong","Please make sure that you have a repository named " ea.repo " on the Gethub servers")
		PopVer()
}}
Edit(){
	default()
	Gui,%win%:TreeView,SysTreeView321
	info:=newwin[]
	cn:=ssn(node(),"descendant::version[@tv='" TV_GetSelection() "']")
	cn.text:=info.edit
}
editgr(){
	static
	global x
	if(A_GuiEvent="I"){
		default()
		Gui,%win%:ListView,SysListView321
		LV_GetText(value,LV_GetNext())
		if(value="Repository Name"){
			new:=new GUIKeep("Repository_Name",newwin.hwnd),controls:={repo:"Repository Name: (Required)",website:"Website URL: (Optional)",description:"Repository Description: (Optional)"}
			for a,b in controls
				new.Add("Text,," b),new.Add("Edit,w300 v" a "," ssn(node(),"@" a).text)
			new.Add("Button,gupdateinfo default,Set Info"),new.Show("Repository Name")
			Gui,%win%:+Disabled
			MouseClick,Left,,,,,U
			return
			updateinfo:
			info:=New[]
			Gui,%win%:-Disabled
			if(info.repo="")
				return m("Repository name is required!")
			for a,b in info
				node().SetAttribute(a,a="repo"?RegExReplace(b,"\s","-"):b)
			Gui,Repository_Name:Destroy
			WinActivate,% newwin.id
			git.repo:=info.repo,git.baseurl:=git.url "/repos/" git.owner "/" git.repo "/",git.refresh(),PopVer(),PopBranch()
			return
		}else{
			ugi:
			nw:=new GUIKeep("UGI",newwin.hwnd),ea:=settings.ea("//github")
			for a,b in ControlList
				nw.add("Text,xm," b),nw.Add("Edit,w300," ea[a])
			nw.add("Button,gUGIEscape,&Save","Button,x+0 ggettoken,Get Token"),nw.show("Update Github Info")
			for a,b in ControlList
				if(b=value){
					ControlFocus,Edit%A_Index%,% nw.id
					ControlSend,Edit%A_Index%,^a,% nw.id
				}
			return
			gettoken:
			Run,https://github.com/settings/applications
			return
			UGIEscape:
			UGIClose:
			if(!gh:=settings.ssn("//github"))
				settings.add("github")
			for a,b in ControlList{
				ControlGetText,value,Edit%A_Index%,% nw.id
				gh.SetAttribute(a,value)
			}
			Gui,ugi:Destroy
			PopVer(),PopBranch()
			WinActivate,% newwin.id
			return
		}
		return
		Repository_Nameclose:
		Gui,Repository_Name:Destroy
		WinActivate,% newwin.id
		Gui,%win%:-Disabled
		return
		Repository_Nameescape:
		Gui,Repository_Name:Destroy
		WinActivate,% newwin.id
		Gui,%win%:-Disabled
		return
}}
encode(text){
	if(text="")
		return
	cp:=0,VarSetCapacity(rawdata,StrPut(text,"utf-8")),sz:=StrPut(text,&rawdata,"utf-8")-1,DllCall("Crypt32.dll\CryptBinaryToString","ptr",&rawdata,"uint",sz,"uint",0x40000001,"ptr",0,"uint*",cp),VarSetCapacity(str,cp*(A_IsUnicode?2:1)),DllCall("Crypt32.dll\CryptBinaryToString","ptr",&rawdata,"uint",sz,"uint",0x40000001,"str",str,"uint*",cp)
	return str
}
Help(){
	m("With the version treeview focused:`n`nRight Click to change a version number`nCtrl+Up/Down to increment versions`nF1 to build a version list (will be copied to your Clipboard)`nF2 to clear the list`nF3 to copy your entire list to the Clipboard`nPress Delete to remove a version`n`nDrag/Drop additional files you want to upload to the window")
}
clearver:
clipboard:=""
ToolTip,,,,2
return
node(){
	global x
	if(!node:=vversion.ssn("//info[@file='" x.call("current","2").file "']"))
		node:=vversion.under(vversion.ssn("//*"),"info"),node.SetAttribute("file",x.call("current","2").file),top:=vversion.under(node,"versions"),next:=vversion.under(top,"version"),next.SetAttribute("number",1)
	return node
}
OneFile(){
	info:=newwin[],node().SetAttribute("onefile",info.onefile)
}
PopBranch(x:=0){
	Default("TreeView","SysTreeView322")
	GuiControl,%win%:-Redraw,SysTreeView322
	tvlist:=[],TV_Delete(),select:=ssn(node(),"@branch").text
	if(!dxml.ssn("//branch")||x=1)
		updatebranches()
	bl:=dxml.sn("//branch")
	while,bb:=bl.item[A_Index-1],ea:=xml.ea(bb)
		(A_Index=1)?(tvlist[ea.name]:=TV_Add(ea.name)):(tvlist[ea.name]:=TV_Add(ea.name,tvlist["master"],"Vis"))
	GuiControl,%win%:+Redraw,SysTreeView322
	TV_Modify(tvlist[select?select:"master"],"Select Vis Focus")
}
PopVer(){
	Default("TreeView","SysTreeView321")
	for a,b in ["SysTreeView321","SysListView321","SysListView322"]
		GuiControl,%win%:-Redraw,%b%
	Gui,%win%:ListView,SysListView321
	all:=sn(mainnode:=node(),"descendant::version"),TV_Delete(),LV_Delete(),ea:=settings.ea("//github")
	while,aa:=all.item[A_Index-1]
		aa.SetAttribute("tv",TV_Add(ssn(aa,"@number").text))
	if(tv:=ssn(node(),"descendant::*[@select=1]/@tv").text){
		TV_Modify(tv,"Select Vis Focus")
		GuiControl,%win%:+Redraw,SysTreeView321
		TV_Modify(tv,"Select Vis Focus")
	}else
		TV_Modify(TV_GetChild(0),"Select Vis Focus")
	while,rem:=ssn(mainnode,"descendant::*[@select=1]")
		rem.RemoveAttribute("select")
	for a,b in ControlList
		LV_Add("",b,a="token"?RegExReplace(ea[a],".","*"):ea[a])
	LV_Add("","Repository Name",ssn(node(),"@repo").text)
	Loop,2
		LV_ModifyCol(A_Index,"AutoHDR")
	Gui,%win%:ListView,SysListView322
	extra:=sn(node(),"files/file"),LV_Delete()
	while,ee:=extra.item[A_Index-1].text{
		SplitPath,ee,file,dir
		LV_Add("",file,dir)
	}
	LV_ModifyCol(1,"AutoHDR")
	for a,b in ["SysTreeView321","SysListView321","SysListView322"]
		GuiControl,%win%:+Redraw,%b%
}
RButton(){
	default(),cn:=ssn(node(),"descendant::version[@tv='" TV_GetSelection() "']")
	InputBox,nv,Enter a new version number,New Version Number,,,,,,,,% ssn(cn,"@number").text
	if(ErrorLevel||nv="")
		return
	cn.SetAttribute("number",nv),PopVer()
}
RefreshBranch(){
	global git
	git.treesha(),PopBranch(1)
}
tv(){
	if(A_GuiEvent="S"){
		default(),cn:=ssn(node(),"descendant::version[@tv='" TV_GetSelection() "']")
		GuiControl,%win%:,Edit1,% cn.text
}}
Update(){
	Default("TreeView","SysTreeView321")
	info:=newwin[],TV_GetText(name,TV_GetSelection())
	/*
		;Fetch the release id for a given release
		;GET /repos/:owner/:repo/releases
		;check release list
		url:=git.url "/repos/" git.owner "/" git.repo "/releases" git.token,id:=git.find("id",git.send("GET",url)),ssn(node(),"descendant::version[@number='" name "']").SetAttribute("id",id),m(node().xml)
		return
	*/
	json:=git.json({tag_name:name,target_commitish:"master",name:name,body:git.utf8(info.edit),draft:info.draft,prerelease:info.prerelease})
	if(release:=ssn(node(),"descendant::*[@number='" name "']/@id").text){
		id:=git.find("id",msg:=git.send("PATCH",git.repourl() "releases/" release git.token,json))
		if(!id)
			m("Something happened",msg,release)
	}else{
		id:=git.find("id",git.send("POST",git.repourl() "releases" git.token,json))
		if(!id)
			return m("Something happened")
		ssn(node(),"descendant::version[@number='" name "']").SetAttribute("id",id)
	}
	vversion.save(1)
}
UpdateBranches(){
	global git
	root:=dxml.ssn("//*"),pos:=1
	if(!dxml.ssn("//branch[@name='master']"))
		top:=dxml.under(root,"branch",{name:"master"})
	info:=git.send("GET",git.baseurl "git/refs/heads" git.token)
	while,RegExMatch(info,"OUi)\x22ref\x22:\x22(.*)\x22",found,pos),pos:=found.Pos(1)+found.len(1){
		item:=StrSplit(found.1,"/").pop()
		if((item:=StrSplit(found.1,"/").pop())!="master"&&dxml.ssn("//branch[@name='" item "']").xml="")
			dxml.under(root,"branch",{name:item})
	}
	dxml.save(1)
}
verhelp(){
	m("Right Click to change a version number`nCtrl+Up/Down to increment versions`nF1 to build a version list (will be copied to your Clipboard)`nF2 to clear the list`nF3 to copy your entire list to the Clipboard`nPress Delete to remove a version")
}
wholelist:
list:=sn(node,"versions/version")
Clipboard:=""
while,ll:=list.item[A_Index-1]
	Clipboard.=ssn(ll,"@number").text "`r`n" Trim(ll.text,"`r`n") "`r`n"
m("Version list copied to your clipboard.","","",Clipboard)
return
DropFiles(a,b,c,d){
	under:=node()
	if(!top:=ssn(under,"files"))
		top:=vversion.under(under,"files")
	for c,d in a
		vversion.under(top,"file",,d)
	PopVer()
}