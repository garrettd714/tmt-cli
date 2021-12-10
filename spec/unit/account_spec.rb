require 'tmt/commands/account'

RSpec.describe Tmt::Commands::Account do
  it "executes `account` command successfully" do
    output = StringIO.new
    ticker = nil
    options = {}
    command = Tmt::Commands::Account.new(ticker, options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
