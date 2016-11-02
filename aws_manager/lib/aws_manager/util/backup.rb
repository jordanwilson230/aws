module AwsManager
  module Util
    class BackUp
      # Determine if the backup of the given date time is keep-able.
      # Note that the proposed strategy is:
      # * Keep the last 24 hours worth of backups
      # * Keep a weeks worth of daily backups
      # * Keep a months (i.e., 31 days) worth of weekly backups
      # * Keep a years (i.e., 365 days) worth of monthly backups
      # * Keep a yearly backup forever
      #
      # @param date_time [DateTime] the date time of the back up
      def self.keep?(date_time, backup_config)
        months = backup_config['months']
        weeks = backup_config['weeks']
        days = backup_config['days']
        hours = backup_config['hours']

        # Keep the last 24 hours worth of backups
        within_n_days?(date_time, 1) ||
          # Keep a weeks worth of daily backups
          (daily_backup?(date_time, hours) && within_n_days?(date_time, 7)) ||
          # Keep a months (i.e., 31 days) worth of weekly backups
          (weekly_backup?(date_time, days, hours) && within_n_days?(date_time, 31)) ||
          # Keep a years (i.e., 365 days) worth of monthly backups
          (monthly_backup?(date_time, weeks, days, hours) &&
           within_n_days?(date_time, 365)) ||
          # Keep a yearly backup forever
          yearly_backup?(date_time, months, weeks, days, hours)
      end

      # Get the week of the month for a date time.
      #
      # @param date_time {DateTime] the date time
      #
      # @return [Int] the week of the month, e.g., 1st, 2nd etc. (1-5)
      def self.get_week_of_month(date_time)
        date_time.cweek - (date_time - date_time.day + 1).cweek + 1
      end

      # Check if the date time is within (exclusive) n days.
      #
      # @param date_time [DateTime] the date time you want to check
      # @param n [Int] the positive number of days we want to check
      #
      # @return [Boolean] +true+ if it is within +n+ days, +false+ otherwise.
      def self.within_n_days?(date_time, n)
        date_time > DateTime.now - n
      end

      # Check if the back up made in the specific date time is a daily backup.
      #
      # @todo take into account the effects of DST
      #
      # @param date_time [DateTime] the date time of the backup
      # @param hours [[Int]] the list of hour of the day (in UTC/GMT) we choose for
      #                      daily backup (0-23)
      #
      # @return [Boolean] +true+ if it is an instance of daily backup, +false+
      #                   otherwise.
      def self.daily_backup?(date_time, hours = [0])
        backup_utc_hour = date_time.strftime('%H').to_i
        hours.inject(false) { |agg, hour| agg || backup_utc_hour == hour }
      end

      # Check if the back up made in the specific date time is a weekly backup.
      #
      # @param date_time [DateTime] the date time of the backup
      # @param days [[Int]] the list of days of the week we choose for weekly backup
      #                     (1-7, Monday is one)
      # @param hours [[Int]] the list of hour of the day (in UTC/GMT) we choose for
      #                      daily backup (0-23)
      #
      # @return [Boolean] +true+ if it is an instance of daily backup, +false+
      #                   otherwise.
      def self.weekly_backup?(date_time, days = [1], hours = [0])
        days.inject(false) { |agg, day| agg || date_time.cwday == day } &&
          daily_backup?(date_time, hours)
      end

      # Check if the back up made in the specific date time is a monthly backup.
      # Note that we take a month to be 31 days and a week starts with Monday.
      #
      # @param date_time [DateTime] the date time of the backup
      # @param weeks [[Int]] the list of weeks of the month we choose for monthly
      #                      backup (1-31)
      # @param days [[Int]] the list of days of the week we choose for weekly backup
      #                     (1-7, Monday is one)
      # @param hours [[Int]] the list of hour of the day (in UTC/GMT) we choose for
      #                      daily backup (0-23)
      #
      # @return [Boolean] +true if it is an instance of daily backup, +false+
      #                   otherwise.
      def self.monthly_backup?(date_time, weeks = [1], days = [1], hours = [0])
        weeks.inject(false) { |agg, week| agg || get_week_of_month(date_time) == week } &&
          weekly_backup?(date_time, days, hours)
      end

      # Check if the back up made in the specific date time is a yearly backup.
      # Note that we take a year to be 365 days.
      #
      # @param date_time [DateTime] the date time of the backup
      # @param months [[Int]] the list of months of the year we choose for yearly
      #                       backup (1-12)
      # @param weeks [[Int]] the list of weeks of the month we choose for monthly
      #                      backup (1-31)
      # @param days [[Int]] the list of days of the week we choose for weekly backup
      #                     (1-7, Monday is one)
      # @param hours [[Int]] the list of hour of the day (in UTC/GMT) we choose for
      #                      daily backup (0-23)
      #
      # @return [Boolean] +true if it is an instance of daily backup, +false+
      #                   otherwise.
      def self.yearly_backup?(date_time, months = [1], weeks = [1],
                              days = [1], hours = [0])
        months.inject(false) { |agg, month| agg || date_time.month == month } &&
          monthly_backup?(date_time, weeks, days, hours)
      end
    end
  end
end
