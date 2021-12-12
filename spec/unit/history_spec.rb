require 'tmt/commands/history'

RSpec.describe Tmt::Commands::History do
  xit "executes `history` command successfully" do
    output = StringIO.new
    ticker = nil
    options = {}
    command = Tmt::Commands::History.new(ticker, options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
