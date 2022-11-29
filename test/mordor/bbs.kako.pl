#============================================================================================================
#
#	掲示板管理 - 過去ログ モジュール
#	bbs.kako.pl
#	---------------------------------------------------------------------------
#	2004.08.24 start
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
		'LOG'	=> \@LOG
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
	my ($subMode, $BASE, $BBS, $Page);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	$BBS = $pSys->{'AD_BBS'};
	
	# 掲示板情報の読み込みとグループ設定
	if (! defined $BBS){
		require './module/nazguls.pl';
		$BBS = NAZGUL->new;
		
		$BBS->Load($Sys);
		$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
		$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	}
	
	# 管理マスタオブジェクトの生成
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($BASE);
	
	if ($subMode eq 'LIST') {													# ログ一覧画面
		PrintKakoLogList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# 処理完了画面
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('過去ログ処理', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# 処理失敗画面
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	# 掲示板情報を設定
	$Page->HTMLInput('hidden', 'TARGET_BBS', $Form->Get('TARGET_BBS'));
	
	$BASE->Print($Sys->Get('_TITLE') . ' - ' . $BBS->Get('NAME', $Form->Get('TARGET_BBS')), 2);
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
	my ($subMode, $err, $BBS);
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	
	# 管理情報を登録
	$BBS->Load($Sys);
	$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	$Sys->Set('ADMIN', $pSys);
	$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'UPDATEINFO') {												# 情報更新
		$err = FunctionUpdateInfo($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATEIDX') {												# index更新
		$err = FunctionUpdateIndex($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'REMOVE') {													# 過去ログ削除
		$err = FunctionLogDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"KAKO($subMode)", 'ERROR:'.$err);
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"KAKO($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$pSys->{'AD_BBS'} = $BBS;
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
	my ($Base) = @_;
	
	$Base->SetMenu('Log List', "'bbs.kako','DISP','LIST'");
	$Base->SetMenu('<hr>', '');
	$Base->SetMenu('Back to System Management', "'sys.bbs','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintKakoLogList
{
	my ($Page, $SYS, $Form) = @_;
	my (@logSet, $ThreadNum, $key, $res, $subj, $i);
	my ($dispSt, $dispEd, $dispNum);
	my ($common, $n, $Logs, $logNum, $date);
	
	$SYS->Set('_TITLE', 'LOG List');
	
	require './module/galadriel.pl';
	require './module/celeborn.pl';
	$Logs = CELEBORN->new;
	
	$Logs->Load($SYS);
	$Logs->GetKeySet('ALL', '', \@logSet);
	
	# 表示数の設定
	$logNum		= @logSet;
	$dispNum	= $Form->Get('DISPNUM_KAKO', 10) || 0;
	$dispSt		= $Form->Get('DISPST_KAKO', 0) || 0;
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $logNum ? $logNum : ($dispSt + $dispNum));
	
	$common		= "DoSubmit('bbs.kako','DISP','LIST');";
	
	# 表示フォームの表示
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('DISPST_KAKO', " . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST_KAKO', ");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td colspan=2 align=right>");
	$Page->Print("Display Number <input type=text name=DISPNUM_KAKO size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"　Display　\" onclick=\"$common\"></td></tr>\n");
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><th style=\"width:30\"><a href=\"javascript:toggleAll('LOGS')\">All</a></th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Date</td></td>\n");
	
	# 権限取得
	my ($isUpdate, $isDelete);
	$isUpdate = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_KAKOCREATE, $SYS->Get('BBS'));
	$isDelete = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_KAKODELETE, $SYS->Get('BBS'));
	
	# 過去ログ一覧の表示
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$n		= $i + 1;
		$key	= $Logs->Get('KEY', $logSet[$i]);
		$subj	= $Logs->Get('SUBJECT', $logSet[$i]);
		$date	= GALADRIEL::GetDateFromSerial(undef, $Logs->Get('DATE', $logSet[$i]), 0);
		
		$Page->Print("<tr><td><input type=checkbox name=LOGS value=$logSet[$i]></td>");
		$Page->Print("<td>$n: $subj</td><td align=center>$key</td>");
		$Page->Print("<td align=center>$date</td></tr>\n");
	}
	$Page->HTMLInput('hidden', 'DISPST_KAKO', '');
	
	$common = "onclick=\"DoSubmit('bbs.kako','FUNC'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=4 align=left>");
	$Page->Print("<input type=button value=\"Update Info\" $common,'UPDATEINFO')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\"Update Index\" $common,'UPDATEIDX')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\"　Remove　\" $common,'REMOVE')\" class=\"delete\"> ")		if ($isDelete);
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログ情報更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionUpdateInfo
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Logs);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_KAKOCREATE, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/celeborn.pl';
	$Logs = CELEBORN->new;
	
	$Logs->Load($Sys);
	$Logs->UpdateInfo($Sys);
	$Logs->Save($Sys);
	
	push @$pLog, '過去ログ情報(kako.idx)を再作成しました。';
	# インデクスを更新する
	if (FunctionUpdateIndex($Sys, $Form, $pLog) != 0){
		push @$pLog, '過去ログindex(index.html)の再作成に失敗しました。手動で更新してください。';
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログindex更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionUpdateIndex
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Logs, $Page);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_KAKOCREATE, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/thorin.pl';
	require './module/celeborn.pl';
	$Logs = CELEBORN->new;
	$Page = THORIN->new;
	
	$Logs->Load($Sys);
	$Logs->UpdateIndex($Sys, $Page);
#	$Logs->Save($Sys);
	
	push @$pLog, 'Recreated the past log index (index.html).';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログ削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLogDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Logs, @logSet, $id, $base, $removePath, @pathList, $logPath, $logPath2, $removePath2, %Dirs, @DirList);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_KAKODELETE, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	@logSet = $Form->GetAtArray('LOGS');
	$base = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/kako';
	
	require './module/earendil.pl';
	require './module/celeborn.pl';
	$Logs = CELEBORN->new;
	$Logs->Load($Sys);
	
	foreach $id (@logSet) {
		next if (! defined $Logs->Get('KEY', $id));
		push @$pLog, 'past log「' . $Logs->Get('SUBJECT', $id) . '」has been removed.';
		
		# 過去ログファイルの削除
		$logPath = $Logs->Get('PATH', $id);
		$removePath = $base . $logPath;
		unlink $removePath . '/' . $Logs->Get('KEY', $id) . '.dat';
		unlink $removePath . '/' . $Logs->Get('KEY', $id) . '.html';
		
		# 過去ログ情報の削除
		$Logs->Delete($id);
		
		# グループ内のログがすべて削除された場合はディレクトリを削除する
		if ($Logs->GetKeySet('PATH', $logPath, \@pathList) == 1) {
			if ($Logs->Get('PATH', $pathList[0], '') eq '') {
				EARENDIL::DeleteDirectory($removePath);
				$Logs->Delete($pathList[0]);
			}
		}
		
		$logPath2 = $logPath;
		while ($logPath2 =~ m|^(/.+)/.+?$|) {
			$logPath2 = $1;
			$removePath2 = $base . $logPath2;
			
			%Dirs = ();
			@DirList = ();
			EARENDIL::GetFolderHierarchy($removePath2, \%Dirs);
			EARENDIL::GetFolderList(\%Dirs, \@DirList, '');
			
			if ($#DirList == -1) {
				EARENDIL::DeleteDirectory($removePath2);
				$Logs->Delete((grep { $Logs->{'PATH'}->{$_} eq $logPath2 } keys %{$Logs->{'PATH'}})[0]);
			}
			else {
				last;
			}
		}
		
	}
	$Logs->Save($Sys);
	
	# インデクスを更新する
	if (FunctionUpdateIndex($Sys, $Form, $pLog) != 0) {
		push @$pLog, 'Failed to recreate the past log index (index.html). Please update manually.';
	}
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
