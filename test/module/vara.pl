#============================================================================================================
#
#	掲示板書き込み支援モジュール 
#
#============================================================================================================
package	VARA;

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
	my $class = shift;
	
	my $obj = {
		'SYS'		=> undef,
		'SET'		=> undef,
		'FORM'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'SECURITY'	=> undef,
		'PLUGIN'	=> undef,
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	初期化
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR(必須)
#	@param	$Form	SAMWISE(必須)
#	@param	$Set	ISILDUR
#	@param	$Thread	BILBO
#	@param	$Conv	GALADRIEL
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ($Sys, $Form, $Set, $Threads, $Conv) = @_;
	
	$this->{'SYS'} = $Sys;
	$this->{'FORM'} = $Form;
	$this->{'SET'} = $Set;
	$this->{'THREADS'} = $Threads;
	$this->{'CONV'} = $Conv;
	
	# モジュールが用意されてない場合はここで生成する
	if (!defined $Set) {
		require './module/isildur.pl';
		$this->{'SET'} = ISILDUR->new;
		$this->{'SET'}->Load($Sys);
	}
	if (!defined $Threads) {
		require './module/baggins.pl';
		$this->{'THREADS'} = BILBO->new;
		$this->{'THREADS'}->Load($Sys);
	}
	if (!defined $Conv) {
		require './module/galadriel.pl';
		$this->{'CONV'} = GALADRIEL->new;
	}
	
	# キャップ管理モジュールロード
	require './module/ungoliants.pl';
	$this->{'SECURITY'} = SECURITY->new;
	$this->{'SECURITY'}->Init($Sys);
	$this->{'SECURITY'}->SetGroupInfo($Sys->Get('BBS'));
	
	# 拡張機能情報管理モジュールロード
	require './module/athelas.pl';
	$this->{'PLUGIN'} = ATHELAS->new;
	$this->{'PLUGIN'}->Load($Sys);
}

#------------------------------------------------------------------------------------------------------------
#
#	書き込み処理 - WriteData
#	-------------------------------------------
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Write
{
	my $this = shift;
	
	# 書き込み前準備
	$this->ReadyBeforeCheck();
	
	my $err = $ZP::E_SUCCESS;
	
	# 入力内容チェック(名前、メール)
	return $err if (($err = $this->NormalizationNameMail()) != $ZP::E_SUCCESS);
	
	# 入力内容チェック(本文)
	return $err if (($err = $this->NormalizationContents()) != $ZP::E_SUCCESS);
	
	# 規制チェック
	return $err if (($err = $this->IsRegulation()) != $ZP::E_SUCCESS);
	
	
	# データの書き込み
	require './module/gondor.pl';
	my $Sys = $this->{'SYS'};
	my $Set = $this->{'SET'};
	my $Form = $this->{'FORM'};
	my $Conv = $this->{'CONV'};
	my $Threads = $this->{'THREADS'};
	my $Sec = $this->{'SECURITY'};
	
	my $threadid = $Sys->Get('KEY');
	$Threads->LoadAttr($Sys);
	
	# 情報欄
	my $datepart = $Conv->GetDate($Set, $Sys->Get('MSEC'));
	my $id = $Conv->MakeIDnew($Sys, 8);
	my $idpart = $Conv->GetIDPart($Set, $Form, $Sec, $id, $Sys->Get('CAPID'), $Sys->Get('KOYUU'), $Sys->Get('AGENT'));
	my $bepart = '';
	my $extrapart = '';
	$Form->Set('datepart', $datepart);
	$Form->Set('idpart', $idpart);
	#$Form->Set('BEID', ''); # type=1|2
	$Form->Set('extrapart', $extrapart);
	
	my $updown = 'top';
	$updown = '' if ($Form->Contain('mail', 'sage'));
	$updown = '' if ($Threads->GetAttr($threadid, 'sagemode'));
	$Sys->Set('updown', $updown);
	
	# 書き込み直前処理
	$err = $this->ReadyBeforeWrite(ARAGORN::GetNumFromFile($Sys->Get('DATPATH')) + 1);
	return $err if ($err != $ZP::E_SUCCESS);
	
	# レス要素の取得
	my $subject = $Form->Get('subject', '');
	my $name = $Form->Get('FROM', '');
	my $mail = $Form->Get('mail', '');
	my $text = $Form->Get('MESSAGE', '');
	
	$datepart = $Form->Get('datepart', '');
	$idpart = $Form->Get('idpart', '');
	$bepart = $Form->Get('BEID', '');
	$extrapart = $Form->Get('extrapart', '');
	my $info = $datepart;
	$info .= " $idpart" if ($idpart ne '');
	$info .= " $bepart" if ($bepart ne '');
	$info .= " $extrapart" if ($extrapart ne '');
	
	my $data = "$name<>$mail<>$info<>$text<>$subject";
	my $line = "$data\n";
	
	my $datPath = $Sys->Get('DATPATH');
	
	# ログ書き込み
	require './module/peregrin.pl';
	my $Log = PEREGRIN->new;
	$Log->Load($Sys, 'WRT', $threadid);
	$Log->Set($Set, length($Form->Get('MESSAGE')), $Sys->Get('VERSION'), $Sys->Get('KOYUU'), $data, $Sys->Get('AGENT', 0));
	$Log->Save($Sys);
	
	# リモートホスト保存(SETTING.TXT変更により、常に保存)
	SaveHost($Sys, $Form);
	
	# datファイルへ直接書き込み
	my $resNum = 0;
	my $err2 = ARAGORN::DirectAppend($Sys, $datPath, $line);
	if ($err2 == 0) {
		# レス数が最大数を超えたらover設定をする
		$resNum = ARAGORN::GetNumFromFile($datPath);
		if ($resNum >= $Sys->Get('RESMAX')) {
			# datにOVERスレッドレスを書き込む
			Get1001Data($Sys, \$line);
			ARAGORN::DirectAppend($Sys, $datPath, $line);
			$resNum++;
		}
		$err = $ZP::E_SUCCESS;
	}
	# datファイル追記失敗
	elsif ($err2 == 1) {
		$err = $ZP::E_POST_NOTEXISTDAT;
	}
	elsif ($err2 == 2) {
		$err = $ZP::E_LIMIT_STOPPEDTHREAD;
	}
	
	if ($err == $ZP::E_SUCCESS) {
		# subject.txtの更新
		# スレッド作成モードなら新規に追加する
		if ($Sys->Equal('MODE', 1)) {
			require './module/earendil.pl';
			my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
			my $Pools = FRODO->new;
			$Pools->Load($Sys);
			$Threads->Add($threadid, $subject, 1);
			
			# スレッド数限界によるdat落ち処理
			my $submax = $Sys->Get('SUBMAX');
			my @tlist;
			$Threads->GetKeySet('ALL', undef, \@tlist);
			foreach my $lid (reverse @tlist) {
				last if ($Threads->GetNum() <= $submax);
				
				# 不落属性あり
				next if ($Threads->GetAttr($lid, 'nopool'));
				
				$Pools->Add($lid, $Threads->Get('SUBJECT', $lid), $Threads->Get('RES', $lid));
				$Threads->Delete($lid);
				EARENDIL::Copy("$path/dat/$lid.dat", "$path/pool/$lid.cgi");
				unlink "$path/dat/$lid.dat";
			}
			
			$Pools->Save($Sys);
			$Threads->Save($Sys);
		}
		# 書き込みモードならレス数の更新
		else {
			$updown = $Sys->Get('updown', '');
			$Threads->OnDemand($Sys, $threadid, $resNum, $updown);
		}
	}
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	前準備
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeCheck
{
	my ($this) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	
	# cookie用にオリジナルを保存する
	my $from = $Form->Get('FROM');
	my $mail = $Form->Get('mail');
	$from =~ s/[\r\n]//g;
	$mail =~ s/[\r\n]//g;
	$Form->Set('NAME', $from);
	$Form->Set('MAIL', $mail);
	
	# キャップパスの抽出と削除
	$Sys->Set('CAPID', '');
	if ($mail =~ s/(?:#|＃)(.+)//) {
		my $capPass = $1;
		
		# キャップ情報設定
		my $capID = $this->{'SECURITY'}->GetCapID($capPass);
		$Sys->Set('CAPID', $capID);
		$Form->Set('mail', $mail);
	}
	
	# datパスの生成
	my $datPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/' . $Sys->Get('KEY') . '.dat';
	$Sys->Set('DATPATH', $datPath);
	
	# 本文禁則文字変換
	my $text = $Form->Get('MESSAGE');
	$this->{'CONV'}->ConvertCharacter1(\$text, 2);
	$Form->Set('MESSAGE', $text);
}

#------------------------------------------------------------------------------------------------------------
#
#	書き込み直前処理
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@param	$res
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeWrite
{
	my $this = shift;
	my ($res) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $Sec = $this->{'SECURITY'};
	my $capID = $Sys->Get('CAPID', '');
	my $bbs = $Form->Get('bbs');
	my $from = $Form->Get('FROM');
	my $koyuu = $Sys->Get('KOYUU');
	my $client = $Sys->Get('CLIENT');
	my $host = $ENV{'REMOTE_HOST'};
	my $addr = $ENV{'REMOTE_ADDR'};
	
	# 規制ユーザ・NGワードチェック
	{
		# 規制ユーザ
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_NGUSER, $bbs)) {
			require './module/faramir.pl';
			my $vUser = FARAMIR->new;
			$vUser->Load($Sys);
			
			my $koyuu2 = ($client & $ZP::C_MOBILE_IDGET & ~$ZP::C_P2 ? $koyuu : undef);
			my $check = $vUser->Check($host, $addr, $koyuu2);
			if ($check == 4) {
				return $ZP::E_REG_NGUSER;
			}
			elsif ($check == 2) {
				return $ZP::E_REG_NGUSER if ($from !~ /$host/i); # $hostは正規表現
				$Form->Set('FROM', "</b>[´･ω･｀] <b>$from");
			}
		}
		
		# NGワード
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_NGWORD, $bbs)) {
			require './module/wormtongue.pl';
			my $ngWord = WORMTONGUE->new;
			$ngWord->Load($Sys);
			my @checkKey = ('FROM', 'mail', 'MESSAGE');
			
			my $check = $ngWord->Check($this->{'FORM'}, \@checkKey);
			if ($check == 3) {
				return $ZP::E_REG_NGWORD;
			}
			elsif ($check == 1) {
				$ngWord->Method($Form, \@checkKey);
			}
			elsif ($check == 2) {
				$Form->Set('FROM', "</b>[´+ω+｀] $host <b>$from");
			}
		}
	}
	
	# pluginに渡す値を設定
	$Sys->Set('_ERR', 0);
	$Sys->Set('_NUM_', $res);
	$Sys->Set('_THREAD_', $this->{'THREADS'});
	$Sys->Set('_SET_', $this->{'SET'});
	
	$this->ExecutePlugin(16);
	
	my $text = $Form->Get('MESSAGE');
	$text =~ s/<br>/ <br> /g;
	$Form->Set('MESSAGE', " $text ");
	
	# 名無し設定
	$from = $Form->Get('FROM', '');
	if ($from eq '') {
		$from = $this->{'SET'}->Get('BBS_NONAME_NAME');
		$Form->Set('FROM', $from);
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン処理
#	-------------------------------------------------------------------------------------
#	@param	$type
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ExecutePlugin
{
	my $this = shift;
	my ($type) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $Plugin = $this->{'PLUGIN'};
	
	# 有効な拡張機能一覧を取得
	my @pluginSet = ();
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	foreach my $id (@pluginSet) {
		# タイプが先呼び出しの場合はロードして実行
		if ($Plugin->Get('TYPE', $id) & $type) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			
			require "./plugin/$file";
			my $Config = PLUGINCONF->new($Plugin, $id);
			my $command = $className->new($Config);
			$command->execute($Sys, $Form, $type);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	規制チェック
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#------------------------------------------------------------------------------------------------------------
sub IsRegulation
{
	my $this = shift;
	
	my $Sys = $this->{'SYS'};
	my $Set = $this->{'SET'};
	my $Sec = $this->{'SECURITY'};
	
	my $bbs = $this->{'FORM'}->Get('bbs');
	my $from = $this->{'FORM'}->Get('FROM');
	my $capID = $Sys->Get('CAPID', '');
	my $datPath = $Sys->Get('DATPATH');
	my $client = $Sys->Get('CLIENT');
	my $mode = $Sys->Get('AGENT');
	my $koyuu = $Sys->Get('KOYUU');
	my $host = $ENV{'REMOTE_HOST'};
	my $addr = $ENV{'REMOTE_ADDR'};
	my $islocalip = 0;
	
	$islocalip = 1 if ($addr =~ /^(127|172|192|10)\./);
	
	# レス書き込みモード時のみ
	if ($Sys->Equal('MODE', 2)) {
		require './module/gondor.pl';
		
		# 移転スレッド
		return $ZP::E_LIMIT_MOVEDTHREAD if (ARAGORN::IsMoved($datPath));
		
		# レス最大数
		return $ZP::E_LIMIT_OVERMAXRES if ($Sys->Get('RESMAX') < ARAGORN::GetNumFromFile($datPath));
		
		# datファイルサイズ制限
		if ($Set->Get('BBS_DATMAX')) {
			my $datSize = int((stat $datPath)[7] / 1024);
			if ($Set->Get('BBS_DATMAX') < $datSize) {
				return $ZP::E_LIMIT_OVERDATSIZE;
			}
		}
	}
	# REFERERチェック
	if ($Set->Equal('BBS_REFERER_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsReferer($this->{'SYS'}, \%ENV)) {
			return $ZP::E_POST_INVALIDREFERER;
		}
	}
	# PROXYチェック
	if (!$islocalip && $Set->Equal('BBS_PROXY_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsProxy($this->{'SYS'}, $this->{'FORM'}, $from, $mode)) {
			#$this->{'FORM'}->Set('FROM', "</b> [―\{}\@{}\@{}-] <b>$from");
			if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_DNSBL, $bbs)) {
				return $ZP::E_REG_DNSBL;
			}
		}
	}
	# 読取専用
	if (!$Set->Equal('BBS_READONLY', 'none')) {
		if (!$Sec->IsAuthority($capID, $ZP::CAP_LIMIT_READONLY, $bbs)) {
			return $ZP::E_LIMIT_READONLY;
		}
	}
	# JPホスト以外規制
	if (!$islocalip && $Set->Equal('BBS_JP_CHECK', 'checked')) {
		if ($host !~ /\.jp$/i) {
			if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_NOTJPHOST, $bbs)) {
				return $ZP::E_REG_NOTJPHOST;
			}
		}
	}
	
	# スレッド作成モード
	if ($Sys->Equal('MODE', 1)) {
		# スレッドキーが重複しないようにする
		my $tPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/';
		my $key = $Sys->Get('KEY');
		$key++ while (-e "$tPath$key.dat");
		$Sys->Set('KEY', $key);
		$datPath = "$tPath$key.dat";
		
		# スレッド作成(携帯から)
		if (!$Set->Equal('BBS_THREADMOBILE', 'checked') && ($client & $ZP::C_MOBILE)) {
			if (!$Sec->IsAuthority($capID, $ZP::CAP_LIMIT_MOBILETHREAD, $bbs)) {
				return $ZP::E_LIMIT_MOBILETHREAD;
			}
		}
		# スレッド作成(キャップのみ)
		if ($Set->Equal('BBS_THREADCAPONLY', 'checked')) {
			if (!$Sec->IsAuthority($capID, $ZP::CAP_LIMIT_THREADCAPONLY, $bbs)) {
				return $ZP::E_LIMIT_THREADCAPONLY;
			}
		}
		# スレッド作成(スレッド立てすぎ)
		require './module/peregrin.pl';
		my $Log = PEREGRIN->new;
		$Log->Load($Sys, 'THR');
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_MANYTHREAD, $bbs)) {
			my $tateHour = $Set->Get('BBS_TATESUGI_HOUR', '0') - 0;
			my $tateCount = $Set->Get('BBS_TATESUGI_COUNT', '0') - 0;
			if ($tateHour != 0 && $tateCount != 0 && $Log->IsTatesugi($tateHour) >= $tateCount) {
				return $ZP::E_REG_MANYTHREAD;
			}
			my $tateClose = $Set->Get('BBS_THREAD_TATESUGI', '0') - 0;
			my $tateCount2 = $Set->Get('BBS_TATESUGI_COUNT2', '0') - 0;
			if ($tateClose != 0 && $tateCount2 != 0 && $Log->Search($koyuu, 3, $mode, $host, $tateClose) >= $tateCount2) {
				return $ZP::E_REG_MANYTHREAD;
			}
		}
		$Log->Set($Set, $Sys->Get('KEY'), $Sys->Get('VERSION'), $koyuu, undef, $mode);
		$Log->Save($Sys);
		
		# Sambaログ
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_SAMBA, $bbs) || !$Sec->IsAuthority($capID, $ZP::CAP_REG_NOTIMEPOST, $bbs)) {
			my $Logs = PEREGRIN->new;
			$Logs->Load($Sys, 'SMB');
			$Logs->Set($Set, $Sys->Get('KEY'), $Sys->Get('VERSION'), $koyuu);
			$Logs->Save($Sys);
		}
	}
	# レス書き込みモード
	else {
		require './module/peregrin.pl';
		
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_SAMBA, $bbs) || !$Sec->IsAuthority($capID, $ZP::CAP_REG_NOTIMEPOST, $bbs)) {
			my $Logs = PEREGRIN->new;
			$Logs->Load($Sys, 'SMB');
			
			my $Logh = PEREGRIN->new;
			$Logh->Load($Sys, 'SBH');
			
			my $n = 0;
			my $tm = 0;
			my $Samba = int($Set->Get('BBS_SAMBATIME', '') eq '' ? $Sys->Get('DEFSAMBA') : $Set->Get('BBS_SAMBATIME'));
			my $Houshi = int($Set->Get('BBS_HOUSHITIME', '') eq '' ? $Sys->Get('DEFHOUSHI') : $Set->Get('BBS_HOUSHITIME'));
			my $Holdtm = int($Sys->Get('SAMBATM'));
			
			# Samba
			if ($Samba && !$Sec->IsAuthority($capID, $ZP::CAP_REG_SAMBA, $bbs)) {
				if ($Houshi) {
					my ($ishoushi, $htm) = $Logh->IsHoushi($Houshi, $koyuu);
					if ($ishoushi) {
						$Sys->Set('WAIT', $htm);
						return $ZP::E_REG_SAMBA_STILL;
					}
				}
				
				($n, $tm) = $Logs->IsSamba($Samba, $koyuu);
			}
				
			# 短時間投稿 (Samba優先)
			if (!$n && $Holdtm && !$Sec->IsAuthority($capID, $ZP::CAP_REG_NOTIMEPOST, $bbs)) {
				$tm = $Logs->IsTime($Holdtm, $koyuu);
			}
			
			$Logs->Set($Set, $Sys->Get('KEY'), $Sys->Get('VERSION'), $koyuu);
			$Logs->Save($Sys);
			
			if ($n >= 6 && $Houshi) {
				$Logh->Set($Set, $Sys->Get('KEY'), $Sys->Get('VERSION'), $koyuu);
				$Logh->Save($Sys);
				$Sys->Set('WAIT', $Houshi);
				return $ZP::E_REG_SAMBA_LISTED;
			}
			elsif ($n) {
				$Sys->Set('SAMBATIME', $Samba);
				$Sys->Set('WAIT', $tm);
				$Sys->Set('SAMBA', $n);
				return ($n > 3 && $Houshi ? $ZP::E_REG_SAMBA_WARNING : $ZP::E_REG_SAMBA_CAUTION);
			}
			elsif ($tm > 0) {
				$Sys->Set('WAIT', $tm);
				return $ZP::E_REG_NOTIMEPOST;
			}
		}
		
		# レス書き込み(連続投稿)
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_NOBREAKPOST, $bbs)) {
			if ($Set->Get('timeclose') && $Set->Get('timecount') ne '') {
				my $Log = PEREGRIN->new;
				$Log->Load($Sys, 'HST');
				my $cnt = $Log->Search($koyuu, 2, $mode, $host, $Set->Get('timecount'));
				if ($cnt >= $Set->Get('timeclose')) {
					return $ZP::E_REG_NOBREAKPOST;
				}
			}
		}
		# レス書き込み(二重投稿)
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_DOUBLEPOST, $bbs)) {
			if ($this->{'SYS'}->Get('KAKIKO') == 1) {
				my $Log = PEREGRIN->new;
				$Log->Load($Sys, 'WRT', $Sys->Get('KEY'));
				if ($Log->Search($koyuu, 1) - 2 == length($this->{'FORM'}->Get('MESSAGE'))) {
					return $ZP::E_REG_DOUBLEPOST;
				}
			}
		}
		
		#$Log->Set($Set, length($this->{'FORM'}->Get('MESSAGE')), $Sys->Get('VERSION'), $koyuu, $datas, $mode);
		#$Log->Save($Sys);
	}
	
	# パスを保存
	$Sys->Set('DATPATH', $datPath);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	名前・メール欄の正規化
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationNameMail
{
	my $this = shift;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $Sec = $this->{'SECURITY'};
	my $Set = $this->{'SET'};
	
	my $name = $Form->Get('FROM');
	my $mail = $Form->Get('mail');
	my $subject = $Form->Get('subject');
	my $bbs = $Form->Get('bbs');
	my $host = $ENV{'REMOTE_HOST'};
	
	# キャップ情報取得
	my $capID = $Sys->Get('CAPID', '');
	my $capName = '';
	my $capColor = '';
	if ($capID && $Sec->IsAuthority($capID, $ZP::CAP_DISP_HANLDLE, $bbs)) {
		$capName = $Sec->Get($capID, 'NAME', 1, '');
		$capColor = $Sec->Get($Sec->{'GROUP'}->GetBelong($capID), 'COLOR', 0, '');
		$capColor = $Set->Get('BBS_CAP_COLOR', '') if ($capColor eq '');
	}
	
	# ＃ -> #
	$this->{'CONV'}->ConvertCharacter0(\$name);
	
	# トリップ変換
	my $trip = '';
	if ($name =~ /\#(.*)$/x) {
		my $key = $1;
		$trip = $this->{'CONV'}->ConvertTrip(\$key, $Set->Get('BBS_TRIPCOLUMN'), $Sys->Get('TRIP12'));
	}
	
	# 特殊文字変換 フォーム情報再設定
	$this->{'CONV'}->ConvertCharacter1(\$name, 0);
	$this->{'CONV'}->ConvertCharacter1(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter1(\$subject, 3);
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	$Form->Set('TRIPKEY', $trip);
	
	# プラグイン実行 フォーム情報再取得
	$this->ExecutePlugin($Sys->Get('MODE'));
	$name = $Form->Get('FROM', '');
	$mail = $Form->Get('mail', '');
	$subject = $Form->Get('subject', '');
	$bbs = $Form->Get('bbs');
	$host = $Form->Get('HOST');
	$trip = $Form->Get('TRIPKEY', '???');
	
	# 2ch互換
	$name =~ s/^ //;
	
	# 禁則文字変換
	$this->{'CONV'}->ConvertCharacter2(\$name, 0);
	$this->{'CONV'}->ConvertCharacter2(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter2(\$subject, 3);
	
	# トリップと名前を結合する
	$name =~ s|\#.*$| </b>◆$trip <b>|x if ($trip ne '');
	
	# fusiana変換 2ch互換
	$this->{'CONV'}->ConvertFusianasan(\$name, $host);
	
	# キャップ名結合
	if ($capName ne '') {
		$name = ($name ne '' ? "$name＠" : '');
		if ($capColor eq '') {
			$name .= "$capName ★";
		}
		else {
			$name .= "<font color=\"$capColor\">$capName ★</font>";
		}
	}
	
	
	# スレッド作成時
	if ($Sys->Equal('MODE', 1)) {
		return $ZP::E_FORM_NOSUBJECT if ($subject eq '');
		# サブジェクト欄の文字数確認
		if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGSUBJECT, $bbs)) {
			if ($Set->Get('BBS_SUBJECT_COUNT') < length($subject)) {
				return $ZP::E_FORM_LONGSUBJECT;
			}
		}
	}
	
	# 名前欄の文字数確認
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGNAME, $bbs)) {
		if ($Set->Get('BBS_NAME_COUNT') < length($name)) {
			return $ZP::E_FORM_LONGNAME;
		}
	}
	# メール欄の文字数確認
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGMAIL, $bbs)) {
		if ($Set->Get('BBS_MAIL_COUNT') < length($mail)) {
			return $ZP::E_FORM_LONGMAIL;
		}
	}
	# 名前欄の入力確認
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_NONAME, $bbs)) {
		if ($Set->Equal('NANASHI_CHECK', 'checked') && $name eq '') {
			return $ZP::E_FORM_NONAME;
		}
	}
	
	# 正規化した内容を再度設定
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	テキスト欄の正規化
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationContents
{
	my $this = shift;
	
	my $Form = $this->{'FORM'};
	my $Sec = $this->{'SECURITY'};
	my $Set = $this->{'SET'};
	my $Sys = $this->{'SYS'};
	my $Conv = $this->{'CONV'};
	
	my $bbs = $Form->Get('bbs');
	my $text = $Form->Get('MESSAGE');
	my $host = $Form->Get('HOST');
	my $capID = $this->{'SYS'}->Get('CAPID', '');
	
	# 禁則文字変換
	$Conv->ConvertCharacter2(\$text, 2);
	
	my ($ln, $cl) = $Conv->GetTextInfo(\$text);
	
	# 本文が無い
	return $ZP::E_FORM_NOTEXT if ($text eq '');
	
	# 本文が長すぎ
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGTEXT, $bbs)) {
		if ($Set->Get('BBS_MESSAGE_COUNT') < length($text)) {
			return $ZP::E_FORM_LONGTEXT;
		}
	}
	# 改行が多すぎ
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_MANYLINE, $bbs)) {
		if (($Set->Get('BBS_LINE_NUMBER') * 2) < $ln) {
			return $ZP::E_FORM_MANYLINE;
		}
	}
	# 1行が長すぎ
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGLINE, $bbs)) {
		if ($Set->Get('BBS_COLUMN_NUMBER') < $cl) {
			return $ZP::E_FORM_LONGLINE;
		}
	}
	# アンカーが多すぎ
	if ($Sys->Get('ANKERS')) {
		if ($Conv->IsAnker(\$text, $Sys->Get('ANKERS'))) {
			return $ZP::E_FORM_MANYANCHOR;
		}
	}
	
	# 本文ホスト表示
	#if (!$Sec->IsAuthority($capID, $ZP::CAP_DISP_NOHOST, $bbs)) {
	#	if ($Set->Equal('BBS_RAWIP_CHECK', 'checked') && $Sys->Equal('MODE', 1)) {
	#		$text .= ' <hr> <font color=tomato face=Arial><b>';
	#		$text .= "$ENV{'REMOTE_ADDR'} , $host , </b></font><br>";
	#	}
	#}
	
	$Form->Set('MESSAGE', $text);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	1001のレスデータを設定する
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$data	1001レス格納バッファ
#
#------------------------------------------------------------------------------------------------------------
sub Get1001Data
{
	
	my ($Sys, $data) = @_;
	
	my $endPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/1000.txt';
	
	# 1000.txtが存在すればその内容、無ければデフォルトの1001を使用する
	if (open(my $fh, '<', $endPath)) {
		flock($fh, 2);
		$$data = <$fh>;
		close($fh);
	}
	else {
		my $resmax = $Sys->Get('RESMAX');
		my $resmax1 = $resmax + 1;
		my $resmaxz = $resmax;
		my $resmaxz1 = $resmax1;
		$resmaxz =~ s/([0-9])/"\x82".chr(0x4f+$1)/eg; # 全角数字
		$resmaxz1 =~ s/([0-9])/"\x82".chr(0x4f+$1)/eg; # 全角数字
		
		$$data = "$resmaxz1<><>Over $resmax Thread<>このスレッドは$resmaxzを超えました。<br>";
		$$data .= 'もう書けないので、新しいスレッドを立ててくださいです。。。<>' . "\n";
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ホストログを出力する
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$data	1001レス格納バッファ
#
#------------------------------------------------------------------------------------------------------------
sub SaveHost
{
	
	my ($Sys, $Form) = @_;
	
	my $bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	my $host = $ENV{'REMOTE_HOST'};
	my $agent = $Sys->Get('AGENT');
	my $koyuu = $Sys->Get('KOYUU');
	
	if ($agent ne '0') {
		if ($agent eq 'P') {
			$host = "$host($koyuu)$ENV{'REMOTE_ADDR'}";
		}
		else {
			$host = "$host($koyuu)";
		}
	}
	
	require './module/imrahil.pl';
	my $Logger = IMRAHIL->new;
	
	if ($Logger->Open("$bbs/log/HOST", $Sys->Get('HSTMAX'), 2 | 4) == 0) {
		$Logger->Put($host, $Sys->Get('KEY'), $Sys->Get('MODE'));
		$Logger->Write();
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
