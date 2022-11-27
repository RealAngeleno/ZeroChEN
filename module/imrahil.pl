#============================================================================================================
#
#	���O�Ǘ����W���[��
#	--------------------------------------
#	Mode�̃r�b�g�ɂ���
#	0:�ǎ��p
#	1:�I�[�v���Ɠ����ɓ��e�ǂݍ���
#	2:�ő�T�C�Y�𒴂������O��ۑ�
#	3�`:���g�p
#
#============================================================================================================
package	IMRAHIL;
use strict;
#use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	�R���X�g���N�^
#	-------------------------------------------------------------------------------------
#	@param	$file	���O�t�@�C���p�X(�g���q����)
#	@param	$limit	���O�ő�T�C�Y
#	@param	$mode	���[�h
#	@return	���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $class = shift;
	my ($file, $limit, $mode) = @_;
	
	my $obj = {
		'PATH'		=> $file,
		'LIMIT'		=> $limit,
		'MODE'		=> $mode,
		'STAT'		=> 0,
		'HANDLE'	=> undef,
		'LOGS'		=> undef,
		'SIZE'		=> undef,
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�X�g���N�^
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DESTROY
{
	my $this = shift;
	
	$this->Close;
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�I�[�v��
#	-------------------------------------------------------------------------------------
#	@param	$file	���O�t�@�C���p�X(�g���q����)
#	@param	$limit	���O�ő�T�C�Y
#	@param	$mode	���[�h
#	@return	����:0,���s:-1
#
#------------------------------------------------------------------------------------------------------------
sub Open
{
	my $this = shift;
	my ($file, $limit, $mode) = @_;
	
	if (defined $file && defined $limit && defined $mode) {
		$this->{'PATH'} = $file;
		$this->{'LIMIT'} = $limit;
		$this->{'MODE'} = $mode;
	}
	else {
		$file = $this->{'PATH'};
		$limit = int $this->{'LIMIT'};
		$mode = int $this->{'MODE'};
	}
	
	$this->Close;
	
	my $ret = -1;
	
	if (!$this->{'STAT'}) {
		$file .= '.cgi';
		if (open(my $fh, (-f $file ? '+<' : '>'), $file)) {
			flock($fh, 2);
			seek($fh, 0, 2);
			binmode($fh);
			
			$this->{'HANDLE'} = $fh;
			$this->{'STAT'} = 1;
			$ret = ($mode & 2 ? $this->Read() : 0);
		}
		else {
			warn "can't open log: $file";
		}
	}
	
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�N���[�Y
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Close
{
	my $this = shift;
	
	if ($this->{'STAT'}) {
		close($this->{'HANDLE'});
		$this->{'HANDLE'} = undef;
		$this->{'STAT'} = 0;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�ǂݍ���
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	����:0,���s:-1
#
#------------------------------------------------------------------------------------------------------------
sub Read
{
	my $this = shift;
	
	if ($this->{'STAT'}) {
		my $fh = $this->{'HANDLE'};
		seek($fh, 0, 0);
		
		my @lines = <$fh>;
		map { s/[\r\n]+\z// } @lines;
		
		$this->{'LOGS'} = \@lines;
		$this->{'SIZE'} = scalar(@lines);
		return 0;
	}
	
	return -1;
}

#------------------------------------------------------------------------------------------------------------
#
#	��������
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Write
{
	my $this = shift;
	
	# �t�@�C���I�[�v����ԂȂ珑�����݂����s����
	if ($this->{'STAT'}) {
		if (!($this->{'MODE'} & 1)) {
			my $fh = $this->{'HANDLE'};
			seek($fh, 0, 0);
			
			for (my $i = 0 ; $i < $this->{'SIZE'} ; $i++) {
				print $fh "$this->{'LOGS'}->[$i]\n";
			}
			
			truncate($fh, tell($fh));
		}
		$this->Close();
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�[�^�擾
#	-------------------------------------------------------------------------------------
#	@param	$line	�擾�f�[�^�s
#	@return	�擾�f�[�^
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($line) = @_;
	
	if ($line >= 0 && $line < $this->{'SIZE'}) {
		return $this->{'LOGS'}->[$line];
	}
	return undef;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�[�^�ǉ�
#	-------------------------------------------------------------------------------------
#	@param	$pData	�ǉ��f�[�^
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Put
{
	my $this = shift;
	my (@datas) = @_;
	
	my $tm = time;
	my $logData = join('<>', $tm, @datas);
	
	push @{$this->{'LOGS'}}, $logData;
	$this->{'SIZE'}++;
	
	if ($this->{'SIZE'} + 10 > $this->{'LIMIT'}) {
		my $logName = "$this->{'PATH'}_old.cgi";
		if (open(my $fh, '>>', $logName)) {
			flock($fh, 2);
			binmode($fh);
			while ($this->{'SIZE'} > $this->{'LIMIT'}) {
				my $old = shift @{$this->{'LOGS'}};
				$this->{'SIZE'}--;
				if ($this->{'MODE'} & 4) {
					print $fh "$old\n";
				}
			}
			close($fh);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�T�C�Y�擾
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�T�C�Y
#
#------------------------------------------------------------------------------------------------------------
sub Size
{
	my $this = shift;
	return $this->{'SIZE'};
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�ޔ�
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub MoveToOld
{
	my $this = shift;
	
	my $logName = "$this->{'PATH'}_old.cgi";
	if (open(my $fh, '>>', $logName)) {
		flock($fh, 2);
		binmode($fh);
		for(my $i = 0 ; $i < $this->{'SIZE'} ; $i++) {
			print $fh "$this->{'LOGS'}->[$i]\n";
		}
		close($fh);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�N���A
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Clear
{
	my $this = shift;
	
	$this->{'LOGS'} = [];
	$this->{'SIZE'} = 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	����
#	-------------------------------------------------------------------------------------
#	@param	$index		�����v�f�̃C���f�N�X
#	@param	$word		�����f�[�^
#	@param	$pResult	���ʊi�[�p�z��̎Q��
#	@return	�q�b�g��
#
#------------------------------------------------------------------------------------------------------------
sub search
{
	my $this = shift;
	my ($index, $word, $pResult) = @_;
	
	my $num = 0;
	for(my $i = 0 ; $i < $this->{'SIZE'} ; $i++) {
		my @elem = split(/<>/, $this->{'LOGS'}->[$i], -1);
		if ($elem[$index] eq $word) {
			push @$pResult, $this->{'LOGS'}->[$i];
			$num++;
		}
	}
	return $num;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;