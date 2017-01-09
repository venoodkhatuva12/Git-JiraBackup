#!/usr/bin/perl

use strict;
use DateTime;
use POSIX qw(strftime);
my @days_in_month=(31,28,31,30,31,30,31,31,30,31,30,31);

#mysql backup details
my $mysql_user="user";
my $mysql_password="password";
my $mysql_host="localhost";
my $mysql_backup_tmp="backup/dir";
my $mysql_backup_date=strftime "%m%d%Y", localtime;
my $mysql_backup_file="git\_$mysql_backup_date\.sql";
my $mysql_com_path="$mysql_backup_tmp\/$mysql_backup_file";

my @backup_db=('mysql','stash');
my $backup_tmp="/backup/mysql";
my $backup_path="/backups/git_backup/git_daily";
my $backup_mpath="/backups/git_backup/git_monthly";
my $backup_date = strftime "%m%d%Y", localtime;
my $backup_directory= strftime "%m%Y", localtime;
my $backup_fdirectory="$backup_path/$backup_directory";

# some date calculation
my $current_date_noformat=DateTime->now(time_zone => 'local');
my $current_day=$current_date_noformat->day;
my $current_day_org=$current_date_noformat->day;
if ($current_day <= 9 )
{
   $current_day="0$current_day";
}
my $current_month=$current_date_noformat->month;
my $current_month_org=$current_date_noformat->month;
my $current_month_array=$current_month-1;
if ($current_month <= 9 )
{
   $current_month="0$current_month";
}
my $current_month_last_day=$days_in_month[$current_month_array];

my $d_month=DateTime::Duration->new(days => 30);
my $d_monthb=$current_date_noformat - $d_month;
#my $d_date_before=$d_monthb->year.$d_monthb->month.$d_monthb->day;
my $d_date_before=$d_monthb->month.$d_monthb->day.$d_monthb->year;

# create local backup directory
if (!(-d $backup_fdirectory))
{

        my $create_directory = "\/bin\/mkdir\ \-p $backup_fdirectory";
        system($create_directory);
}
&mysql_tmp_backup();
my $gzip_path=$backup_fdirectory."/stash-".$backup_date.".tar.gz  /apps/stash-home $mysql_com_path";
my $gzip_command="/bin/tar -Pzcf " . $gzip_path;
system($gzip_command);
&git_external_backup();
&git_s3_backup();
&git_intmonthly_backup();
#&git_del_daily();

sub mysql_tmp_backup
{
   my $mysqldump="\/usr\/bin\/mysqldump\ \-u $mysql_user \-p$mysql_password \-\-events \-\-all-databases \|  \/bin\/gzip \-9  \> $mysql_com_path  ";
   system($mysqldump);
}
sub git_external_backup
{
}
sub git_s3_backup
{
 my $git_s3cp_cmd="\/usr\/local\/bin\/s3cmd put $backup_fdirectory\/backup\-$backup_date.tar.gz  s3:\/\/git-backup\/git\/git_daily\/backup\-$backup_date\.tar\.gz";
 system($git_s3cp_cmd);
}
sub git_intmonthly_backup
{
    if ($current_day_org eq 1)
    {
         my $intbname="stash\_$backup_date.tar.gz";
         my $m_cp_cmd="\/bin\/cp $backup_fdirectory\/stash\-$backup_date.tar.gz $backup_mpath\/.";
  my $m_s3_cmd="\/usr\/local\/bin\/s3cmd put $backup_fdirectory\/backup\-$backup_date.tar.gz  s3:\/\/hit-backup\/git\/git_monthly\/backup\-$backup_date\.tar\.gz";
         system($m_cp_cmd);
         system($m_s3_cmd);
    }
}
sub git_del_daily
{
   my $del_directory=$d_monthb->month.$d_monthb->year;
   my $del_backup_directory="/storage/git_backup/git_daily\/$del_directory";
   if (!(-d $del_backup_directory))
   {
     print "The log does not exist\n";
   }
   else
   {
     my $del_backup_path="$del_backup_directory\/stash\_$d_date_before\.tar\.gz";
     my $del_s3_path="s3:\/\/git-backup-2016\/git\/git_daily\/backup\-$d_date_before\.tar\.gz";
     my $del_int_cmd="\/bin\/rm \-rf $del_backup_path";
     my $del_s3_cmd="\/apps\/s3cmd\/s3cmd\ del $del_s3_path";
     system($del_int_cmd);
     system($del_s3_cmd);
   }
}
