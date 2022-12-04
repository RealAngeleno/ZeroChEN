#============================================================================================================
#
#	システム管理 - 掲示板 モジュール
#	sys.bbs.pl
#	---------------------------------------------------------------------------
#	2004.01.31 start
#
#============================================================================================================
package	MODULE;

use strict;
#use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj, @LOG);
	
	$obj = {
		LOG	=> \@LOG
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($BASE, $Page, $subMode);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	
	# 管理情報を登録
	$Sys->Set('ADMIN', $pSys);
	
	# 管理マスタオブジェクトの生成
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($BASE, $pSys);
	
	if ($subMode eq 'LIST') {														# 掲示板一覧画面
		PrintBBSList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CREATE') {													# 掲示板作成画面
		PrintBBSCreate($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'DELETE') {													# 掲示板削除確認画面
		PrintBBSDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CATCHANGE') {												# 掲示板カテゴリ変更画面
		PrintBBScategoryChange($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CATEGORY') {												# カテゴリ一覧画面
		PrintCategoryList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CATEGORYADD') {												# カテゴリ追加画面
		PrintCategoryAdd($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CATEGORYDEL') {												# カテゴリ削除画面
		PrintCategoryDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# 処理完了画面
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('掲示板処理', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# 処理失敗画面
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	$BASE->Print($Sys->Get('_TITLE'), 1);
}

#------------------------------------------------------------------------------------------------------------
#
#	機能メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($subMode, $err);
	
	# 管理情報を登録
	$Sys->Set('ADMIN', $pSys);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'CREATE') {														# 掲示板作成
		$err = FunctionBBSCreate($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# 掲示板削除
		$err = FunctionBBSDelete($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'CATCHANGE') {												# カテゴリ変更
		$err = FunctionCategoryChange($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'CATADD') {													# カテゴリ追加
		$err = FunctionCategoryAdd($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'CATDEL') {													# カテゴリ削除
		$err = FunctionCategoryDelete($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATE') {													# 掲示板情報更新
		$err = FunctionBBSInfoUpdate($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATEBBS') {												# 掲示板更新
		$err = FunctionBBSUpdate($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "BBS($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "BBS($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$this->DoPrint($Sys, $Form, $pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューリスト設定
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys) = @_;
	
	$Base->SetMenu('Board List', "'sys.bbs','DISP','LIST'");
	
	# システム管理権限のみ
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('Create New Board', "'sys.bbs','DISP','CREATE'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('List by Category', "'sys.bbs','DISP','CATEGORY'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSList
{
	my ($Page, $SYS, $Form) = @_;
	my ($BBS, $Category, @bbsSet, @catSet, $id, $name, $category, $subject);
	my ($common1, $common2, $sCat, @belongBBS, $belongID, $isSysad);
	
	$SYS->Set('_TITLE', 'BBS List');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	$BBS->Load($SYS);
	$Category->Load($SYS);
	
	$sCat = $Form->Get('BBS_CATEGORY', '');
	
	# ユーザ所属のBBS一覧を取得
	$SYS->Get('ADMIN')->{'SECINFO'}->GetBelongBBSList($SYS->Get('ADMIN')->{'USER'}, $BBS, \@belongBBS);
	
	# システム管理権限を取得
	$isSysad = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_SYSADMIN, '*');
	
	# 掲示板情報を取得
	if ($sCat eq '' || $sCat eq 'ALL') {
		$BBS->GetKeySet('ALL', '', \@bbsSet);
	}
	else {
		$BBS->GetKeySet('CATEGORY', $sCat, \@bbsSet);
	}
	$Category->GetKeySet(\@catSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=4 align=right>category");
	$Page->Print("<select name=BBS_CATEGORY>");
	$Page->Print("<option value=ALL>all</option>\n");
	
	# カテゴリリストを出力
	foreach $id (@catSet) {
		$name = $Category->Get('NAME', $id);
		if ($id eq $sCat) {
			$Page->Print("<option value=\"$id\" selected>$name</option>\n");
		}
		else {
			$Page->Print("<option value=\"$id\">$name</option>\n");
		}
	}
	$Page->Print("</select><input type=button value=\"List\" onclick=");
	$Page->Print("\"DoSubmit('sys.bbs','DISP','LIST')\"></td></tr>\n");
	
	# 掲示板リストを出力
	$Page->Print("<tr><td style=\"width:20\"> </th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">BBS Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Category</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Description</th></tr>\n");
	
	foreach $id (@bbsSet) {
		# 所属掲示板のみ表示
		foreach $belongID (@belongBBS) {
			if ($id eq $belongID) {
				$name		= $BBS->Get('NAME', $id);
				$subject	= $BBS->Get('SUBJECT', $id);
				$category	= $BBS->Get('CATEGORY', $id);
				$category	= $Category->Get('NAME', $category);
				
				$common1 = "\"javascript:SetOption('TARGET_BBS','$id');";
				$common1 .= "DoSubmit('bbs.thread','DISP','LIST');\"";
				
				$Page->Print("<tr><td><input type=checkbox name=BBSS value=$id></td>");
				$Page->Print("<td><a href=$common1>$name</a></td><td>$category</td>");
				$Page->Print("<td>$subject</td></tr>\n");
			}
		}
	}
	$common1 = "onclick=\"DoSubmit('sys.bbs','FUNC'";
	$common2 = "onclick=\"DoSubmit('sys.bbs','DISP'";
	
	$Page->HTMLInput('hidden', 'TARGET_BBS', '');
	$Page->Print("<tr><td colspan=4 align=left><hr>");
	$Page->Print("<input type=button value=\"Change Category\" $common2,'CATCHANGE')\"> ")	if (1);
	$Page->Print("<input type=button value=\"Update Information\" $common1,'UPDATE')\"> ")		if ($isSysad);
	$Page->Print("<input type=button value=\"Update index\" $common1,'UPDATEBBS')\"> ")	if (1);
	$Page->Print("<input type=button value=\"Delete\" $common2,'DELETE')\" class=\"delete\"> ")		if ($isSysad);
	$Page->Print("</td></tr></table>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板作成画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSCreate
{
	my ($Page, $SYS, $Form) = @_;
	my ($BBS, $Category, @bbsSet, @catSet, $id, $name);
	
	$SYS->Set('_TITLE', 'BBS Create');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	$BBS->Load($SYS);
	$Category->Load($SYS);
	
	# 掲示板情報を取得
	$BBS->GetKeySet('ALL', '', \@bbsSet);
	$Category->GetKeySet(\@catSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>Set each item and press the [Create] button.</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Board category</td>");
	$Page->Print("<td><select name=BBS_CATEGORY>");
	
	# output category list
	foreach $id (@catSet) {
		$name = $Category->Get('NAME', $id);
		$Page->Print("<option value=\"$id\">$name</option>\n");
	}
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Bulletin Board Directory</td><td>");
	$Page->Print("<input type=text size=60 name=BBS_DIR value=\"[directory name]\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Board name</td><td>");
	$Page->Print("<input type=text size=60 name=BBS_NAME value=\"[BBS name] @ 0ch BBS\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Description</td><td>");
	$Page->Print("<input type=text size=60 name=BBS_EXPLANATION value=\"[Description]\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Inherit settings from another board?</td>");
	$Page->Print("<td><select name=BBS_INHERIT>");
	$Page->Print("<option value=\"\">No</option>\n");
	
	# 掲示板リストを出力
	foreach $id (@bbsSet) {
		$name = $BBS->Get('NAME', $id);
		$Page->Print("<option value=$id>$name</option>\n");
	}
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"Create\" ");
	$Page->Print("onclick=\"DoSubmit('sys.bbs','FUNC','CREATE')\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板削除確認画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSDelete
{
	my ($Page, $SYS, $Form) = @_;
	my ($BBS, $Category, @bbsSet, $id, $name, $subject, $category);
	
	$SYS->Set('_TITLE', 'BBS Delete Confirm');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	$BBS->Load($SYS);
	$Category->Load($SYS);
	
	@bbsSet = $Form->GetAtArray('BBSS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>Delete the following board(s)<br><br></td></tr>");
	
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">BBS Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Category</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">SubScription</th></tr>\n");
	
	# 掲示板リストを出力
	foreach $id (@bbsSet) {
		$name		= $BBS->Get('NAME', $id);
		$subject	= $BBS->Get('SUBJECT', $id);
		$category	= $BBS->Get('CATEGORY', $id);
		$category	= $Category->Get('NAME', $category);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$category</td>");
		$Page->Print("<td>$subject</td></tr>\n");
		$Page->HTMLInput('hidden', 'BBSS', $id);
	}
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("NOTE: Deleted boards can never be restored, so they will be gone forever (a very long time)!</b></td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td colspan=3 align=left><input type=button value=\"Delete\" ");
	$Page->Print("onclick=\"DoSubmit('sys.bbs','FUNC','DELETE')\" class=\"delete\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板カテゴリ変更画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBScategoryChange
{
	my ($Page, $SYS, $Form) = @_;
	my ($BBS, $Category, @bbsSet, @catSet, $id, $name, $subject, $category);
	
	$SYS->Set('_TITLE', 'Category Change');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	$BBS->Load($SYS);
	$Category->Load($SYS);
	
	@bbsSet = $Form->GetAtArray('BBSS');
	$Category->GetKeySet(\@catSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>Change the categories of the following bulletin board(s)<br><br></td></tr>");
	
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">BBS Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Category</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">SubScription</th></tr>\n");
	
	# 掲示板リストを出力
	foreach $id (@bbsSet) {
		$name		= $BBS->Get('NAME', $id);
		$subject	= $BBS->Get('SUBJECT', $id);
		$category	= $BBS->Get('CATEGORY', $id);
		$category	= $Category->Get('NAME', $category);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$category</td>");
		$Page->Print("<td>$subject</td></tr>\n");
		$Page->HTMLInput('hidden', 'BBSS', $id);
	}
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td colspan=3 align=right>Change to <select name=SEL_CATEGORY>");
	
	# カテゴリリストを出力
	foreach $id (@catSet) {
		$name = $Category->Get('NAME', $id);
		$Page->Print("<option value=\"$id\">$name</option>\n");
	}
	$Page->Print("</select><input type=button value=\"Submit\" ");
	$Page->Print("onclick=\"DoSubmit('sys.bbs','FUNC','CATCHANGE')\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ一覧画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintCategoryList
{
	my ($Page, $SYS, $Form) = @_;
	my ($Category, $BBS, $id, $name, $subj, $common);
	my (@catsSet, @bbsSet, $bbsNum);
	
	$SYS->Set('_TITLE', 'Category List');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	
	$BBS->Load($SYS);
	$Category->Load($SYS);
	$Category->GetKeySet(\@catsSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td style=\"width:20\"> </th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Category Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:300\">SubScription</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Belonging</th></tr>\n");
	
	# カテゴリ一覧の出力
	foreach $id (@catsSet) {
		$BBS->GetKeySet('CATEGORY', $id, \@bbsSet);
		
		$name	= $Category->Get('NAME', $id);
		$subj	= $Category->Get('SUBJECT', $id);
		$bbsNum	= @bbsSet;
		
		$Page->Print("<tr><td><input type=checkbox name=CATS value=$id>");
		$Page->Print("</td><td>$name</td><td>$subj</td>");
		$Page->Print("<td align=center>$bbsNum</td></tr>\n");
		undef @bbsSet;
	}
	$common = "onclick=\"DoSubmit('sys.bbs','DISP'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	$Page->Print("<tr><td colspan=4 align=left>");
	$Page->Print("<input type=button value=\"Add\" $common,'CATEGORYADD')\"> ");
	$Page->Print("<input type=button value=\"Remove\" $common,'CATEGORYDEL')\" class=\"delete\"> ");
	$Page->Print("</td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ追加画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintCategoryAdd
{
	my ($Page, $SYS, $Form) = @_;
	my ($common);
	
	$SYS->Set('_TITLE', 'Category Add');
	$common = "onclick=\"DoSubmit('sys.bbs','FUNC','CATADD');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>Set each item and press the Add button.</td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Category Name</td><td><input type=text name=NAME size=60></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Category Description</td><td><input type=text name=SUBJ size=60></td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"Add\" $common>");
	$Page->Print("</td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ削除画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintCategoryDelete
{
	my ($Page, $SYS, $Form) = @_;
	my ($Category, $name, $subj, @catSet, $id);
	
	$SYS->Set('_TITLE', 'Category Delete Confirm');
	
	require './module/nazguls.pl';
	$Category = ANGMAR->new;
	$Category->Load($SYS);
	
	@catSet = $Form->GetAtArray('CATS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>Delete the following categories<br><br></td></tr>");
	
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Category Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">SubScription</th></tr>\n");
	
	# ユーザリストを出力
	foreach $id (@catSet) {
		$name = $Category->Get('NAME', $id);
		$subj = $Category->Get('SUBJECT', $id);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$subj</td></tr>\n");
		$Page->HTMLInput('hidden', 'CATS', $id);
	}
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=2><b><font color=red>");
	$Page->Print("NOTE: Deleted categories cannot be restored.</b><br>");
	$Page->Print("※NOTE: Boards with this catagory will be changed to general!</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"Delete\" ");
	$Page->Print("onclick=\"DoSubmit('sys.bbs','FUNC','CATDEL')\" class=\"delete\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板の生成
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSCreate
{
	my ($Sys, $Form, $pLog) = @_;
	my ($bbsCategory, $bbsDir, $bbsName, $bbsExplanation, $bbsInherit);
	my ($createPath, $dataPath);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my @inList = ('BBS_DIR', 'BBS_NAME', 'BBS_CATEGORY');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		if (! $Form->IsBBSDir(['BBS_DIR'])) {
			return 1002;
		}
	}
	require './module/earendil.pl';
	
	# POSTデータの取得
	$bbsCategory	= $Form->Get('BBS_CATEGORY');
	$bbsDir			= $Form->Get('BBS_DIR');
	$bbsName		= $Form->Get('BBS_NAME');
	$bbsExplanation	= $Form->Get('BBS_EXPLANATION');
	$bbsInherit		= $Form->Get('BBS_INHERIT');
	
	# パスの設定
	$createPath		= $Sys->Get('BBSPATH') . '/' . $bbsDir;
	$dataPath		= '.' . $Sys->Get('DATA');
	
	# 掲示板ディレクトリの作成に成功したら、その下のディレクトリを作成する
	if (! (EARENDIL::CreateDirectory($createPath, $Sys->Get('PM-BDIR')))) {
		return 2000;
	}
	
	# サブディレクトリ生成
	EARENDIL::CreateDirectory("$createPath/i", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/dat", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/log", $Sys->Get('PM-LDIR'));
	EARENDIL::CreateDirectory("$createPath/kako", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/pool", $Sys->Get('PM-ADIR'));
	EARENDIL::CreateDirectory("$createPath/info", $Sys->Get('PM-ADIR'));
	
	# デフォルトデータのコピー
	EARENDIL::Copy("$dataPath/default_img.gif", "$createPath/kanban.gif");
	EARENDIL::Copy("$dataPath/default_bac.gif", "$createPath/ba.gif");
	EARENDIL::Copy("$dataPath/default_hed.txt", "$createPath/head.txt");
	EARENDIL::Copy("$dataPath/default_fot.txt", "$createPath/foot.txt");
	EARENDIL::Copy("$dataPath/index.html", "$createPath/log/index.html");
	EARENDIL::Copy("$dataPath/index.html", "$createPath/pool/index.html");
	EARENDIL::Copy("$dataPath/index.html", "$createPath/info/index.html");
	
	push @$pLog, "BBS directory generation completed...[$createPath]";
	
	# 設定継承情報のコピー
	if ($bbsInherit ne '') {
		my ($BBS, $inheritPath);
		require './module/nazguls.pl';
		$BBS = NAZGUL->new;
		$BBS->Load($Sys);
		
		$inheritPath = $Sys->Get('BBSPATH') . '/' . $BBS->Get('DIR', $bbsInherit);
		EARENDIL::Copy("$inheritPath/SETTING.TXT", "$createPath/SETTING.TXT");
		EARENDIL::Copy("$inheritPath/info/groups.cgi", "$createPath/info/groups.cgi");
		EARENDIL::Copy("$inheritPath/info/capgroups.cgi", "$createPath/info/capgroups.cgi");
		
		push @$pLog, "Configuration inheritance complete...[$inheritPath]";
	}
	
	my ($bbsSetting);
	
	# 掲示板設定情報生成
	require './module/isildur.pl';
	$bbsSetting = ISILDUR->new;
	
	$Sys->Set('BBS', $bbsDir);
	$bbsSetting->Load($Sys);
	
	require './module/galadriel.pl';
	my $createPath2 = GALADRIEL::MakePath($Sys->Get('CGIPATH'), $createPath);
	my $cookiePath = GALADRIEL::MakePath($Sys->Get('CGIPATH'), $Sys->Get('BBSPATH'));
	$cookiePath .= '/' if ($cookiePath ne '/');
	$bbsSetting->Set('BBS_TITLE', $bbsName);
	$bbsSetting->Set('BBS_SUBTITLE', $bbsExplanation);
	$bbsSetting->Set('BBS_BG_PICTURE', "$createPath2/ba.gif");
	$bbsSetting->Set('BBS_TITLE_PICTURE', "$createPath2/kanban.gif");
	$bbsSetting->Set('BBS_COOKIEPATH', $cookiePath);
	
	$bbsSetting->Save($Sys);
	
	push @$pLog, 'Board setup complete...';
	
	# 掲示板構成要素生成
	my ($BBSAid);
	require './module/varda.pl';
	$BBSAid = VARDA->new;
	
	$Sys->Set('MODE', 'CREATE');
	$BBSAid->Init($Sys, $bbsSetting);
	$BBSAid->CreateIndex();
	$BBSAid->CreateIIndex();
	$BBSAid->CreateSubback();
	
	push @$pLog, 'BBS construction element generation complete...';
	
	# 過去ログインデクス生成
	require './module/thorin.pl';
	require './module/celeborn.pl';
	my $PastLog = CELEBORN->new;
	my $Page = THORIN->new;
	$PastLog->Load($Sys);
	$PastLog->UpdateInfo($Sys);
	$PastLog->UpdateIndex($Sys, $Page);
	$PastLog->Save($Sys);
	
	push @$pLog, 'Past login decks generation complete...';
	
	# 掲示板情報に追加
	require './module/nazguls.pl';
	my $BBS = NAZGUL->new;
	$BBS->Load($Sys);
	$BBS->Add($bbsName, $bbsDir, $bbsExplanation, $bbsCategory);
	$BBS->Save($Sys);
	
	push @$pLog, 'Bulletin board information added';
	push @$pLog, "Name: $bbsName";
	push @$pLog, " Subject: $bbsExplanation";
	push @$pLog, "Category: $bbsCategory";
	push @$pLog, '<hr>Created a bulletin board at the URL below. ';
	push @$pLog, "<a href=\"$createPath/\" target=_blank>$createPath/</a>";
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板の更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	my ($BBSAid, $BBS, @bbsSet, $id, $bbs, $name);
	
	require './module/nazguls.pl';
	require './module/varda.pl';
	$BBS = NAZGUL->new;
	$BBSAid = VARDA->new;
	
	$BBS->Load($Sys);
	@bbsSet = $Form->GetAtArray('BBSS');
	
	foreach $id (@bbsSet) {
		$bbs = $BBS->Get('DIR', $id, '');
		next if ($bbs eq '');
		$name = $BBS->Get('NAME', $id);
		$Sys->Set('BBS', $bbs);
		$Sys->Set('MODE', 'CREATE');
		$BBSAid->Init($Sys, undef);
		$BBSAid->CreateIndex();
		$BBSAid->CreateIIndex();
		$BBSAid->CreateSubback();
		
		push @$pLog, "Board '$name' has been updated.";
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板情報の更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSInfoUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	my ($BBS);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	
	$BBS->Load($Sys);
	$BBS->Update($Sys, '');
	$BBS->Save($Sys);
	
	push @$pLog, 'Board information has been updated successfully.';
	push @$pLog, 'All categories have been changed to "General" and should be reset.';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板の削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my ($BBS, @bbsSet, $id, $dir, $name, $path);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	require './module/earendil.pl';
	$BBS = NAZGUL->new;
	$BBS->Load($Sys);
	
	@bbsSet = $Form->GetAtArray('BBSS');
	
	foreach $id (@bbsSet) {
		$dir	= $BBS->Get('DIR', $id);
		next if (! defined $dir);
		$name	= $BBS->Get('NAME', $id);
		$path	= $Sys->Get('BBSPATH') . "/$dir";
		
		# 掲示板ディレクトリと掲示板情報の削除
		EARENDIL::DeleteDirectory($path);
		$BBS->Delete($id);
		
		push @$pLog, "Deleted board '$name($dir).'<br>";
	}
	$BBS->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリの追加
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryAdd
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Category, $name, $subj);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	$Category = ANGMAR->new;
	
	$Category->Load($Sys);
	
	$name = $Form->Get('NAME');
	$subj = $Form->Get('SUBJ');
	
	$Category->Add($name, $subj);
	$Category->Save($Sys);
	
	# ログの設定
	{
		push @$pLog, '<b>Add category</b>';
		push @$pLog, "Category name: $name";
		push @$pLog, "Category description: $subj";
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリの削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Category, $BBS, $name, $id, $bbsID);
	my (@categorySet, @bbsSet);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	$BBS		= NAZGUL->new;
	$Category	= ANGMAR->new;
	
	$BBS->Load($Sys);
	$Category->Load($Sys);
	
	@categorySet = $Form->GetAtArray('CATS');
	
	foreach $id (@categorySet) {
		if ($id ne '0000000001') {
			$name = $Category->Get('NAME', $id);
			$BBS->GetKeySet('CATEGORY', $id, \@bbsSet);
			foreach $bbsID (@bbsSet) {
				$BBS->Set($bbsID, 'CATEGORY', '0000000001');
			}
			undef @bbsSet;
			$Category->Delete($id);
			push @$pLog, "Deleted category '$name'";
		}
	}
	$BBS->Save($Sys);
	$Category->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリの変更
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryChange
{
	my ($Sys, $Form, $pLog) = @_;
	my ($BBS, $Category, @bbsSet, $idCat, $nmCat, $nmBBS, $id);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	$BBS		= NAZGUL->new;
	$Category	= ANGMAR->new;
	
	$BBS->Load($Sys);
	$Category->Load($Sys);
	
	@bbsSet	= $Form->GetAtArray('BBSS');
	$idCat	= $Form->Get('SEL_CATEGORY');
	$nmCat	= $Category->Get('NAME', $idCat);
	
	foreach $id (@bbsSet) {
		$BBS->Set($id, 'CATEGORY', $idCat);
		$nmBBS = $BBS->Get('NAME', $id);
		push @$pLog, "Changed '$nmBBS' category to '$nmCat.'";
	}
	
	$BBS->Save($Sys);
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
