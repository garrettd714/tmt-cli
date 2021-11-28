require 'tmt/commands/tasty_stream'

RSpec.describe Tmt::Commands::TastyStream do
  xit "executes `tasty_stream` command successfully" do
    output = StringIO.new
    id = nil
    bid = nil
    ask = nil
    options = {}
    command = Tmt::Commands::TastyStream.new(id, bid, ask, options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
