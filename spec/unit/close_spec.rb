require 'tmt/commands/close'

RSpec.describe Tmt::Commands::Close do
  xit "executes `close` command successfully" do
    output = StringIO.new
    id = nil
    mark = nil
    options = {}
    command = Tmt::Commands::Close.new(id, mark, options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
