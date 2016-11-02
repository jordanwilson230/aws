require 'spec_helper'

describe AwsManager::Util::BackUp, unit: true do
  describe '::get_week_of_month' do
    context 'given nil' do
      it 'raise error' do
        expect { AwsManager::Util::BackUp.get_week_of_month(nil) }.to raise_error
      end
    end
    context 'given 28 Feb 1901' do
      it 'returns 5' do
        dt = DateTime.new(1901, 2, 28)
        expect(AwsManager::Util::BackUp.get_week_of_month(dt)).to eq(5)
      end
    end
    context 'given 14 Nov 2014' do
      it 'returns 3' do
        dt = DateTime.new(2014, 11, 14)
        expect(AwsManager::Util::BackUp.get_week_of_month(dt)).to eq(3)
      end
    end
  end

  describe '::within_n_days?' do
    let(:today) { DateTime.now }
    context 'given `n`' do
      context 'is nil' do
        it 'raise error' do
          expect { AwsManager::Util::BackUp.within_n_days?(DateTime.now, nil) }.to raise_error
        end
      end
      context 'has value 10' do
        let(:n) { 10 }
        context 'given today' do
          it 'returns true' do
            expect(AwsManager::Util::BackUp.within_n_days?(today, n)).to be true
          end
        end
        context 'given 9 days ago' do
          it 'returns true' do
            expect(AwsManager::Util::BackUp.within_n_days?(today - 9, n)).to be true
          end
        end
        context 'given 10 days ago' do
          it 'returns false' do
            expect(AwsManager::Util::BackUp.within_n_days?(today - 10, n)).to be false
          end
        end
        context 'given 11 days ago' do
          it 'returns false' do
            expect(AwsManager::Util::BackUp.within_n_days?(today - 11, n)).to be false
          end
        end
      end
    end
  end

  describe '::daily_backup?' do
    context 'given `hours` = [0]' do
      context 'given `date_time`' do
        context 'is nil' do
          it 'raise error' do
            expect { AwsManager::Util::BackUp.daily_backup?(nil, [0]) }.to raise_error
          end
        end
        context 'is_not daily backup' do
          it 'returns false' do
            dt = DateTime.new(1999, 9, 9, 11, 27, 41)
            expect(AwsManager::Util::BackUp.daily_backup?(dt, [0])).to be false
          end
        end
        context 'is daily backup' do
          it 'returns true' do
            dt = DateTime.new(1999, 9, 9, 0, 27, 41)
            expect(AwsManager::Util::BackUp.daily_backup?(dt, [0])).to be true
          end
        end
      end
    end
  end

  describe '::weekly_backup?' do
    context 'given `days` = [1], `hours` = [0]' do
      context 'given `date_time`' do
        context 'is nil' do
          it 'raise error' do
            expect { AwsManager::Util::BackUp.weekly_backup?(nil, [1], [0]) }.to raise_error
          end
        end
        context '`day` is_not weekly backup' do
          it 'returns false' do
            dt = DateTime.new(1999, 9, 9, 11, 27, 41) # a Thursday
            expect(AwsManager::Util::BackUp.weekly_backup?(dt, [1], [0])).to be false
          end
        end
        context '`hour` is_not weekly backup' do
          it 'returns false' do
            dt = DateTime.new(1999, 9, 6, 11, 27, 41) # a Monday
            expect(AwsManager::Util::BackUp.weekly_backup?(dt, [1], [0])).to be false
          end
        end
        context 'is weekly backup' do
          it 'returns true' do
            dt = DateTime.new(1999, 9, 6, 0, 27, 41) # a Monday
            expect(AwsManager::Util::BackUp.weekly_backup?(dt, [1], [0])).to be true
          end
        end
      end
    end
  end

  describe '::monthly_backup?' do
    context 'given `weeks` = [1], `days` = [1], `hours` = [0]' do
      context 'given `date_time`' do
        context 'is nil' do
          it 'raise error' do
            expect { AwsManager::Util::BackUp.monthly_backup?(nil, [1], [1], [0]) }.to raise_error
          end
        end
        context '`week` is_not monthly backup' do
          it 'returns false' do
            dt = DateTime.new(1999, 8, 20, 0, 27, 41) # 3rd week
            expect(AwsManager::Util::BackUp.monthly_backup?(dt, [1], [1], [0])).to be false
          end
        end
        context '`day` is_not monthly backup' do
          it 'returns false' do
            dt = DateTime.new(1999, 8, 3, 0, 27, 41) # 1st week, Tuesday
            expect(AwsManager::Util::BackUp.monthly_backup?(dt, [1], [1], [0])).to be false
          end
        end
        context '`hour` is_not monthly backup' do
          it 'returns false' do
            dt = DateTime.new(1999, 3, 1, 11, 27, 41) # 1st week, Monday
            expect(AwsManager::Util::BackUp.monthly_backup?(dt, [1], [1], [0])).to be false
          end
        end
        context 'is monthly backup' do
          it 'returns true' do
            dt = DateTime.new(1999, 3, 1, 0, 27, 41) # 1st week, Monday
            expect(AwsManager::Util::BackUp.monthly_backup?(dt, [1], [1], [0])).to be true
          end
        end
      end
    end
  end

  describe '::yearly_backup?' do
    context 'given `months` = [1], `weeks` = [1], `days` = [1], `hours` = [0]' do
      context 'given `date_time`' do
        context 'is nil' do
          it 'raise error' do
            expect{
              AwsManager::Util::BackUp.yearly_backup?(nil, [1], [1], [1], [0])
            }.to raise_error
          end
        end
        context '`month` is_not yearly backup' do
          it 'returns false' do
            dt = DateTime.new(1894, 12, 1, 0, 27, 41) # December
            expect(AwsManager::Util::BackUp.yearly_backup?(dt, [1], [1], [1], [0])).to be false
          end
        end
        context '`week` is_not yearly backup' do
          it 'returns false' do
            dt = DateTime.new(1894, 1, 8, 0, 27, 41) # 1st month, 2nd week
            expect(AwsManager::Util::BackUp.yearly_backup?(dt, [1], [1], [1], [0])).to be false
          end
        end
        context '`day` is_not yearly backup' do
          it 'returns false' do
            dt = DateTime.new(1894, 1, 2, 0, 27, 41) # 1st month & week, Tuesday
            expect(AwsManager::Util::BackUp.yearly_backup?(dt, [1], [1], [1], [0])).to be false
          end
        end
        context '`hour` is_not yearly backup' do
          it 'returns false' do
            dt = DateTime.new(1894, 1, 1, 9, 27, 41) # 1st month & week, Monday
            expect(AwsManager::Util::BackUp.yearly_backup?(dt, [1], [1], [1], [0])).to be false
          end
        end
        context 'is yearly backup' do
          it 'returns true' do
            dt = DateTime.new(1894, 1, 1, 0, 27, 41) # 1st month & week, Tuesday
            expect(AwsManager::Util::BackUp.yearly_backup?(dt, [1], [1], [1], [0])).to be true
          end
        end
      end
    end
  end

  describe '::keep?' do
    before(:each) {
      allow(DateTime).to receive(:now) {
        DateTime.new(2014, 11, 14, 12, 30, 00)
      }
    }

    let(:config) {
      { 'months'  => [2],   # February
        'weeks'   => [2],   # 2nd weke of the month
        'days'    => [2],   # Tuesday
        'hours'   => [2] }  # 0200 - 0259
    }
    let(:alternate_config) {
      { 'months'  => [4, 8, 12], # April, August and December
        'weeks'   => [2],   # 2nd weke of the month
        'days'    => [2],   # Tuesday
        'hours'   => [2]
      }  # 0200 - 0259
    }

    context 'given `backup_config`' do
      context 'is nil' do
        it 'raise error' do
          expect { AwsManager::Util::BackUp.keep?(DateTime.now, nil) }.to raise_error
        end
      end
      context 'produce [2], [2], [2], [2]' do
        context 'given `date_time`' do
          context 'Keep the last 24 hours worth of backups' do
            it 'returns true for within 24 hours' do
              dt = DateTime.now - Rational(1, 2) # Half a day ago
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be true
            end
          end
          context 'Keep a weeks worth of daily backups' do
            it 'returns true for within a week and is daily backup' do
              dt = DateTime.new(2014, 11, 11, 2, 30, 00)
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be true
            end
            it 'returns false for within a week but is not daily backup' do
              dt = DateTime.new(2014, 11, 11, 1, 30, 00)
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be false
            end
          end
          context 'Keep a months worth of weekly backups' do
            it 'returns true for within a month and is weekly backup' do
              dt = DateTime.new(2014, 11, 11, 2, 30, 00)
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be true
            end
            it 'returns false for within a month but is not weekly backup' do
              dt = DateTime.new(2014, 11, 5, 2, 30, 00)
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be false
            end
          end
          context 'Keep a years worth of monthly backups' do
            it 'returns true for within a year and is monthly backup' do
              dt = DateTime.new(2014, 7, 8, 2, 30, 00)
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be true
            end
            it 'returns false for within a year but is not monthly backup' do
              dt = DateTime.new(2014, 1, 2, 2, 30, 00)
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be false
            end
          end
          context 'Keep a yearly backup forever' do
            it 'returns true for yearly backup' do
              dt = DateTime.new(1834, 2, 4, 2, 30, 00)
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be true
            end
            it 'returns false for non-yearly backup' do
              dt = DateTime.new(1871, 12, 25, 2, 30, 00)
              expect(AwsManager::Util::BackUp.keep?(dt, config)).to be false
            end
          end
        end
      end
      context 'produce [4,8,12], [2], [2], [2]' do
        context 'Keep a yearly backup forever' do
          it 'returns true for backup in Apr, Aug and Dec' do
            apr = DateTime.new(1779, 4, 6, 2, 30, 00)
            aug = DateTime.new(1779, 8, 3, 2, 30, 00)
            dec = DateTime.new(1779, 12, 7, 2, 30, 00)
            to_keep = [apr, aug, dec].inject(true) { |agg, dt|
              agg && AwsManager::Util::BackUp.keep?(dt, alternate_config)
            }
            expect(to_keep).to be true
          end
        end
      end
    end
  end
end
