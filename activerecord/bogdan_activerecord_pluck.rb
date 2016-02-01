require "diffbench"
#require 'perftools'
require "bundler"
Bundler.require
$:.unshift "../railties/lib"
$:.unshift "../activesupport/lib"
$:.unshift "../activemodel/lib"
$:.unshift "../activerecord/lib"
require "active_record"
require 'rails'

#require 'perftools'


ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.configurations = true

#ActiveRecord::Base.logger = TEST_LOGGER




ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(:version => 1) do

  create_table :groups do |t|
    t.string :name
    t.float :rating
    t.timestamps
  end

  class ::Group < ActiveRecord::Base
    has_many :entries
  end
end

Group.transaction do
  10000.times do
    Group.connection.execute("insert into groups (name, rating) values (?, ?)", a: "hello"+rand(10000).to_s, b: rand(10) )
  end
end

puts "Groups:"  + Group.count.to_s


GC.disable
DiffBench.bm do
  #PerfTools::CpuProfiler.start("/tmp/add_numbers_profile#{ENV['NUM']}") do
    [
      10,
      100,
      1000,
      10000
    ].each do |amount|
      [
        [:name],
        [:id, :name],
        [:id, :name, :rating]
      ].each do |columns|
        report "pluck #{columns.size} columns and #{amount} records" do
          (10_000 / amount).times do
            Group.limit(amount).pluck(*columns)
          end
          #GC.start
        end
      end
    #end
  end
end



=begin
                    user     system      total        real
-----------------------------pluck 1 columns and 10 records
After patch:    0.120000   0.000000   0.120000 (  0.125344)
Before patch:   0.130000   0.010000   0.140000 (  0.136894)
Improvement: 8%

-----------------------------pluck 2 columns and 10 records
After patch:    0.150000   0.010000   0.160000 (  0.157452)
Before patch:   0.160000   0.000000   0.160000 (  0.171012)
Improvement: 8%

-----------------------------pluck 3 columns and 10 records
After patch:    0.170000   0.000000   0.170000 (  0.178856)
Before patch:   0.190000   0.010000   0.200000 (  0.193022)
Improvement: 7%

----------------------------pluck 1 columns and 100 records
After patch:    0.030000   0.000000   0.030000 (  0.028619)
Before patch:   0.030000   0.000000   0.030000 (  0.036457)
Improvement: 21%

----------------------------pluck 2 columns and 100 records
After patch:    0.040000   0.000000   0.040000 (  0.037713)
Before patch:   0.050000   0.000000   0.050000 (  0.047892)
Improvement: 21%

----------------------------pluck 3 columns and 100 records
After patch:    0.040000   0.010000   0.050000 (  0.042278)
Before patch:   0.050000   0.010000   0.060000 (  0.053374)
Improvement: 21%

---------------------------pluck 1 columns and 1000 records
After patch:    0.020000   0.000000   0.020000 (  0.017872)
Before patch:   0.020000   0.000000   0.020000 (  0.024972)
Improvement: 28%

---------------------------pluck 2 columns and 1000 records
After patch:    0.020000   0.000000   0.020000 (  0.024940)
Before patch:   0.040000   0.000000   0.040000 (  0.033943)
Improvement: 27%

---------------------------pluck 3 columns and 1000 records
After patch:    0.030000   0.000000   0.030000 (  0.027810)
Before patch:   0.030000   0.000000   0.030000 (  0.039015)
Improvement: 29%

--------------------------pluck 1 columns and 10000 records
After patch:    0.010000   0.000000   0.010000 (  0.016477)
Before patch:   0.030000   0.000000   0.030000 (  0.024243)
Improvement: 32%

--------------------------pluck 2 columns and 10000 records
After patch:    0.030000   0.000000   0.030000 (  0.023728)
Before patch:   0.030000   0.010000   0.040000 (  0.033059)
Improvement: 28%

--------------------------pluck 3 columns and 10000 records
After patch:    0.020000   0.000000   0.020000 (  0.026993)
Before patch:   0.030000   0.000000   0.030000 (  0.038090)
Improvement: 29%
=end
