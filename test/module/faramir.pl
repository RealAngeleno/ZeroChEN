#============================================================================================================
#
#	アクセスユーザ管理モジュール
#
#============================================================================================================
package	FARAMIR;

use strict;
#use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	モジュールコンストラクタ - new
#	-------------------------------------------
#	引　数：なし
#	戻り値：モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $class = shift;
	
	my $obj = {
		'TYPE'		=> undef,
		'METHOD'	=> undef,
		'USER'		=> undef,
		'SYS'		=> undef,
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザデータ読み込み - Load
#	-------------------------------------------
#	引　数：$Sys : MELKOR
#	戻り値：正常読み込み:0,エラー:1
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	
	$this->{'SYS'} = $Sys;
	$this->{'USER'} = [];
	
	my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . "/info/access.cgi";
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @datas = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @datas;
		
		my @head = split(/<>/, shift(@datas), -1);
		$this->{'TYPE'} = $head[0];
		$this->{'METHOD'} = $head[1];
		
		push @{$this->{'USER'}}, @datas;
		return 0;
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザデータ書き込み - Save
#	-------------------------------------------
#	引　数：$Sys : MELKOR
#	戻り値：正常書き込み:0,エラー:-1
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	
	my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . "/info/access.cgi";
	
	chmod($Sys->Get('PM-ADM'), $path);
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		
		print $fh "$this->{'TYPE'}<>$this->{'METHOD'}\n";
		foreach (@{$this->{'USER'}}) {
			print $fh "$_\n";
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	chmod($Sys->Get('PM-ADM'), $path);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ追加 - Set
#	-------------------------------------------
#	引　数：$name : 追加ユーザ
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($name) = @_;
	
	push @{$this->{'USER'}}, $name;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザデータ取得 - Get
#	-------------------------------------------
#	引　数：$key : 取得キー
#			$default : デフォルト
#	戻り値：ユーザデータ
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	
	my $val = $this->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザクリア - Clear
#	-------------------------------------------
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Clear
{
	my $this = shift;
	
	$this->{'USER'} = [];
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザデータ設定 - SetData
#	-------------------------------------------
#	引　数：$key  : 設定キー
#			$data : 設定データ
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $data) = @_;
	
	$this->{$key} = $data;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ調査 - Check
#	-------------------------------------------
#	引　数：$host : 調査ホスト
#			$addr : 調査IPアドレス
#			$koyuu : 端末固有識別子
#	戻り値：登録ユーザ:1,未登録ユーザ:0
#
#------------------------------------------------------------------------------------------------------------
sub Check
{
	my $this = shift;
	my ($host, $addr, $koyuu) = @_;
	
	my $Sys = $this->{'SYS'};
	my $addrb = unpack('B32', pack('C*', split(/\./, $addr)));
	my $flag = 0;
	my $adex = '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}';
	
	foreach my $line (@{$this->{'USER'}}) {
		next if ($line =~ /^[#;]|^$/);
		
		# IPアドレス/CIDR
		if ($line =~ m|^($adex)(?:/([0-9]+))?$|) {
			my $leng = $2 || 32;
			my $a = unpack("B$leng", pack('C*', split(/\./, $1)));
			if (substr($addrb, 0, $leng) eq $a) {
				$flag = 1;
				$Sys->Set('HITS', $line);
				last;
			}
		}
		# IPアドレス範囲指定
		elsif ($line =~ m|^($adex)-($adex)$|) {
			my $a = unpack('B32', pack('C*', split(/\./, $1)));
			my $b = unpack('B32', pack('C*', split(/\./, $2)));
			($b, $a) = ($a, $b) if ($a gt $b);
			if ($addrb ge $a && $addrb le $b) {
				$flag = 1;
				$Sys->Set('HITS', $line);
				last;
			}
		}
		# 端末固有識別子
		elsif (defined $koyuu && $koyuu =~ /^\Q$line\E$/) {
			$flag = 1;
			$Sys->Set('HITS', $line);
			last;
		}
		# ホスト名(正規表現)
		elsif ($host =~ /$line/) {
			$flag = 1;
			$Sys->Set('HITS', $line);
			last;
		}
	}
	
	# 規制ユーザ
	if ($flag && $this->{'TYPE'} eq 'disable') {
		if ($this->{'METHOD'} eq 'disable') {
			# 処理：書き込み不可
			return 4;
		}
		elsif ($this->{'METHOD'} eq 'host') {
			# 処理：ホスト表示
			return 2;
		}
		else {
			return 4;
		}
	}
	# 限定ユーザ以外
	elsif (! $flag && $this->{'TYPE'} eq 'enable') {
		if ($this->{'METHOD'} eq 'disable') {
			# 処理：書き込み不可
			return 4;
		}
		elsif ($this->{'METHOD'} eq 'host') {
			# 処理：ホスト表示
			return 2;
		}
		else {
			return 4;
		}
	}
	return 0;
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;
