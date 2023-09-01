require_relative '../lib/hledger_forecast'
require 'stringio'

def strip_ansi_codes(str)
  str.gsub(/\e\[([;\d]+)?m/, "")
end

def capture_stdout
  old_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end

RSpec.describe HledgerForecast::Comparator do
  let(:file1_content) do
    <<~CSV
      "account","2023-07","2023-08","2023-09"
      "total","£100.00","€200.00",0
    CSV
  end

  let(:file2_content) do
    <<~CSV
      "account","2023-07","2023-08","2023-09"
      "total","£110.00","-€200.00",£1144.00
    CSV
  end

  let(:file1) { StringIO.new(file1_content) }
  let(:file2) { StringIO.new(file2_content) }

  before do
    allow(CSV).to receive(:read).with('file1.csv').and_return(CSV.parse(file1.read))
    allow(CSV).to receive(:read).with('file2.csv').and_return(CSV.parse(file2.read))
  end

  it "compares the contents of two CSV files and outputs the difference" do
    comparator = described_class.new

    expected_output = strip_ansi_codes(<<~OUTPUT)
      +---------+---------+----------+---------+
      | account | 2023-07 | 2023-08  | 2023-09 |
      +---------+---------+----------+---------+
      | total   | £10.00  | €-400.00 | 1144.00 |
      +---------+---------+----------+---------+
    OUTPUT

    actual_output = capture_stdout { comparator.compare('file1.csv', 'file2.csv') }
    expect(strip_ansi_codes(actual_output)).to eq(expected_output)
  end
end
