## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2017 Pivotal Software, Inc.  All rights reserved.

## Mock command for command specific parser
defmodule RabbitMQ.CLI.Seagull.Commands.HerringGullCommand do
  @behaviour RabbitMQ.CLI.CommandBehaviour
  use RabbitMQ.CLI.DefaultOutput
  def usage(), do: ["herring_gull"]
  def validate(_,_), do: :ok
  def merge_defaults(_,_), do: {[], %{}}
  def banner(_,_), do: ""
  def run(_,_), do: :ok
  def switches(), do: [herring: :string, garbage: :boolean]
  def aliases(), do: [h: :herring, g: :garbage]
end

defmodule RabbitMQ.CLI.Seagull.Commands.PacificGullCommand do
  @behaviour RabbitMQ.CLI.CommandBehaviour
  use RabbitMQ.CLI.DefaultOutput
  def usage(), do: ["pacific_gull"]
  def validate(_,_), do: :ok
  def merge_defaults(_,_), do: {[], %{}}
  def banner(_,_), do: ""
  def run(_,_), do: :ok
end

defmodule RabbitMQ.CLI.Seagull.Commands.HermannGullCommand do
  @behaviour RabbitMQ.CLI.CommandBehaviour
  use RabbitMQ.CLI.DefaultOutput
  def usage(), do: ["hermann_gull"]
  def validate(_,_), do: :ok
  def merge_defaults(_,_), do: {[], %{}}
  def banner(_,_), do: ""
  def run(_,_), do: :ok
end

defmodule ParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import TestHelper

  @subject RabbitMQ.CLI.Core.Parser

  setup_all do
    Code.ensure_loaded(RabbitMQ.CLI.Seagull.Commands.HerringGullCommand)
    Code.ensure_loaded(RabbitMQ.CLI.Seagull.Commands.PacificGullCommand)
    set_scope(:seagull)
    on_exit(fn ->
      set_scope(:none)
    end)
    :ok
  end

  test "one arity 0 command, no options" do
    assert @subject.parse_global(["sandwich"]) == {["sandwich"], %{}, []}
  end

  test "one arity 1 command, no options" do
    assert @subject.parse_global(["sandwich", "pastrami"]) == {["sandwich", "pastrami"], %{}, []}
  end

  test "no commands, no options (empty string)" do
    assert @subject.parse_global([""]) == {[""], %{}, []}
  end

  test "no commands, no options (empty array)" do
    assert @subject.parse_global([]) == {[],%{}, []}
  end

  test "one arity 1 command, one double-dash quiet flag" do
    assert @subject.parse_global(["sandwich", "pastrami", "--quiet"]) ==
      {["sandwich", "pastrami"], %{quiet: true}, []}
  end

  test "one arity 1 command, one single-dash quiet flag" do
    assert @subject.parse_global(["sandwich", "pastrami", "-q"]) ==
      {["sandwich", "pastrami"], %{quiet: true}, []}
  end

  test "one arity 0 command, one single-dash node option" do
    assert @subject.parse_global(["sandwich", "-n", "rabbitmq@localhost"]) ==
      {["sandwich"], %{node: :"rabbitmq@localhost"}, []}
  end

  test "one arity 1 command, one single-dash node option" do
    assert @subject.parse_global(["sandwich", "pastrami", "-n", "rabbitmq@localhost"]) ==
      {["sandwich", "pastrami"], %{node: :"rabbitmq@localhost"}, []}
  end

  test "one arity 1 command, one single-dash node option and one quiet flag" do
    assert @subject.parse_global(["sandwich", "pastrami", "-n", "rabbitmq@localhost", "--quiet"]) ==
      {["sandwich", "pastrami"], %{node: :"rabbitmq@localhost", quiet: true}, []}
  end

  test "single-dash node option before command" do
    assert @subject.parse_global(["-n", "rabbitmq@localhost", "sandwich", "pastrami"]) ==
      {["sandwich", "pastrami"], %{node: :"rabbitmq@localhost"}, []}
  end

  test "no commands, one double-dash node option" do
    assert @subject.parse_global(["--node=rabbitmq@localhost"]) == {[], %{node: :"rabbitmq@localhost"}, []}
  end

  test "no commands, one integer --timeout value" do
    assert @subject.parse_global(["--timeout=600"]) == {[], %{timeout: 600}, []}
  end

  test "no commands, one string --timeout value is invalid" do
    assert @subject.parse_global(["--timeout=sandwich"]) == {[], %{}, [{"--timeout", "sandwich"}]}
  end

  test "no commands, one float --timeout value is invalid" do
    assert @subject.parse_global(["--timeout=60.5"]) == {[], %{}, [{"--timeout", "60.5"}]}
  end

  test "no commands, one integer -t value" do
    assert @subject.parse_global(["-t", "600"]) == {[], %{timeout: 600}, []}
  end

  test "no commands, one string -t value is invalid" do
    assert @subject.parse_global(["-t", "sandwich"]) == {[], %{}, [{"-t", "sandwich"}]}
  end

  test "no commands, one float -t value is invalid" do
    assert @subject.parse_global(["-t", "60.5"]) == {[], %{}, [{"-t", "60.5"}]}
  end

  test "no commands, one single-dash -p option" do
    assert @subject.parse_global(["-p", "sandwich"]) == {[], %{vhost: "sandwich"}, []}
  end

  test "global parse treats command-specific arguments as invalid (ignores them)" do
    command_line = ["seagull", "--herring", "atlantic", "-g", "-p", "my_vhost"]
    {args, options, invalid} = @subject.parse_global(command_line)
    assert {args, options, invalid} ==
      {["seagull", "atlantic"], %{vhost: "my_vhost"}, [{"--herring", nil}, {"-g", nil}]}
  end

  test "global parse treats command-specific arguments that are separated by an equals sign as invalid (ignores them)" do
    command_line = ["seagull", "--herring=atlantic", "-g", "-p", "my_vhost"]
    {args, options, invalid} = @subject.parse_global(command_line)
    assert {args, options, invalid} ==
      {["seagull"], %{vhost: "my_vhost"}, [{"--herring", nil}, {"-g", nil}]}
  end

  test "command-specific parse recognizes command switches" do
    command_line = ["seagull", "--herring", "atlantic", "-g", "-p", "my_vhost"]
    command = RabbitMQ.CLI.Seagull.Commands.HerringGullCommand
    assert @subject.parse_command_specific(command_line, command) ==
      {["seagull"], %{vhost: "my_vhost", herring: "atlantic", garbage: true}, []}
  end

  test "command-specific parse recognizes command switches that are separated by an equals sign" do
    command_line = ["seagull", "--herring=atlantic", "-g", "-p", "my_vhost"]
    command = RabbitMQ.CLI.Seagull.Commands.HerringGullCommand
    assert @subject.parse_command_specific(command_line, command) ==
      {["seagull"], %{vhost: "my_vhost", herring: "atlantic", garbage: true}, []}
  end

  test "command-specific switches and aliases are optional" do
    command_line = ["seagull", "-p", "my_vhost"]
    command = RabbitMQ.CLI.Seagull.Commands.PacificGullCommand
    assert @subject.parse_command_specific(command_line, command) ==
      {["seagull"], %{vhost: "my_vhost"}, []}
  end

  test "parse/1 returns command name" do
    command_line = ["pacific_gull", "fly", "-p", "my_vhost"]
    command = RabbitMQ.CLI.Seagull.Commands.PacificGullCommand
    assert @subject.parse(command_line) ==
      {command, "pacific_gull", ["fly"], %{vhost: "my_vhost"}, []}
  end

  test "parse/1 returns command name when a global flag comes before the command" do
    command_line = ["-p", "my_vhost", "pacific_gull", "fly"]
    command = RabbitMQ.CLI.Seagull.Commands.PacificGullCommand
    assert @subject.parse(command_line) ==
      {command, "pacific_gull", ["fly"], %{vhost: "my_vhost"}, []}
  end

  test "parse/1 returns command name when a global flag separated by an equals sign comes before the command" do
    command_line = ["-p=my_vhost", "pacific_gull", "fly"]
    command = RabbitMQ.CLI.Seagull.Commands.PacificGullCommand
    assert @subject.parse(command_line) ==
      {command, "pacific_gull", ["fly"], %{vhost: "my_vhost"}, []}
  end

  test "parse/1 returns :no_command when given an empty argument list" do
    command_line = ["-p", "my_vhost"]
    assert @subject.parse(command_line) ==
      {:no_command, "", [], %{vhost: "my_vhost"}, []}
  end

  test "parse/1 returns :no_command and command name when command isn't known" do
    command_line = ["atlantic_gull", "-p", "my_vhost"]
    assert @subject.parse(command_line) ==
      {:no_command, "atlantic_gull", [], %{vhost: "my_vhost"}, []}
  end

  test "parse/1 returns :no command if command-specific options come before the command" do
    command_line = ["--herring", "atlantic", "herring_gull", "-p", "my_vhost"]
    assert @subject.parse(command_line) ==
      {:no_command, "atlantic", ["herring_gull"],
       %{vhost: "my_vhost"}, [{"--herring", nil}]}
  end

  test "parse/1 returns command name if a global option comes before the command" do
    command_line = ["-p", "my_vhost", "herring_gull"]
    command = RabbitMQ.CLI.Seagull.Commands.HerringGullCommand
    assert @subject.parse(command_line) ==
      {command, "herring_gull", [], %{vhost: "my_vhost"}, []}
  end

  test "parse/1 returns command name if multiple global options come before the command" do
    command_line = ["-p", "my_vhost", "-q", "-n", "rabbit@test", "herring_gull"]
    command = RabbitMQ.CLI.Seagull.Commands.HerringGullCommand
    assert @subject.parse(command_line) ==
      {command, "herring_gull", [], %{vhost: "my_vhost", node: :rabbit@test, quiet: true}, []}
  end

  test "parse/1 returns command name if multiple global options separated by an equals sign come before the command" do
    command_line = ["-p=my_vhost", "-q", "--node=rabbit@test", "herring_gull"]
    command = RabbitMQ.CLI.Seagull.Commands.HerringGullCommand
    assert @subject.parse(command_line) ==
      {command, "herring_gull", [], %{vhost: "my_vhost", node: :rabbit@test, quiet: true}, []}
  end

  test "parse/1 returns command with command specific options" do
    command_line = ["herring_gull", "--herring", "atlantic",
                    "-g", "fly", "-p", "my_vhost"]
    command = RabbitMQ.CLI.Seagull.Commands.HerringGullCommand
    assert @subject.parse(command_line) ==
      {command, "herring_gull", ["fly"],
       %{vhost: "my_vhost", herring: "atlantic", garbage: true}, []}
  end

  test "parse/1 returns command with command specific options that are separated by an equals sign" do
    command_line = ["herring_gull", "--herring=atlantic",
                    "-g", "fly", "-p=my_vhost"]
    command = RabbitMQ.CLI.Seagull.Commands.HerringGullCommand
    assert @subject.parse(command_line) ==
      {command, "herring_gull", ["fly"],
       %{vhost: "my_vhost", herring: "atlantic", garbage: true}, []}
  end

  test "parse/1 returns invalid/extra options for command" do
    command_line = ["pacific_gull", "fly",
                    "--herring", "atlantic",
                    "-p", "my_vhost"]
    pacific_gull = RabbitMQ.CLI.Seagull.Commands.PacificGullCommand
    assert @subject.parse(command_line) ==
      {pacific_gull, "pacific_gull", ["fly", "atlantic"],
       %{vhost: "my_vhost"},
       [{"--herring", nil}]}
  end

  test "parse/1 suggests similar command" do
    # One letter difference
    assert @subject.parse(["pacific_gulf"]) ==
      {{:suggest, "pacific_gull"}, "pacific_gulf", [], %{}, []}

    # One letter missing
    assert @subject.parse(["pacific_gul"]) ==
      {{:suggest, "pacific_gull"}, "pacific_gul", [], %{}, []}

    # One letter extra
    assert @subject.parse(["pacific_gulll"]) ==
      {{:suggest, "pacific_gull"}, "pacific_gulll", [], %{}, []}

    # Five letter difference
    assert @subject.parse(["pacifistcatl"]) ==
      {{:suggest, "pacific_gull"}, "pacifistcatl", [], %{}, []}

    # Five letters missing
    assert @subject.parse(["pacific"]) ==
      {{:suggest, "pacific_gull"}, "pacific", [], %{}, []}

    # Closest to similar
    assert @subject.parse(["herrdog_gull"]) ==
      {{:suggest, "herring_gull"}, "herrdog_gull", [], %{}, []}

    # Closest to similar
    assert @subject.parse(["hermaug_gull"]) ==
      {{:suggest, "hermann_gull"}, "hermaug_gull", [], %{}, []}
  end

  @tag cd: "fixtures"
  test "parse/1 supports aliases" do
    aliases = """
    larus_pacificus = pacific_gull
    gull_with_herring = herring_gull --herring atlantic
    flying_gull  = herring_gull fly
    garbage_gull = herring_gull -g
    complex_gull = herring_gull --herring pacific -g --formatter=erlang eat
    invalid_gull = herring_gull --invalid
    unknown_gull = misterious_gull
    """

    aliases_file_name = "aliases.ini"
    File.write(aliases_file_name, aliases)
    on_exit(fn() ->
      File.rm(aliases_file_name)
    end)

    assert @subject.parse(["larus_pacificus", "--aliases-file", aliases_file_name]) ==
      {RabbitMQ.CLI.Seagull.Commands.PacificGullCommand,
       "larus_pacificus",
       [],
       %{aliases_file: aliases_file_name},
       []}

    assert @subject.parse(["gull_with_herring", "--aliases-file", aliases_file_name]) ==
      {RabbitMQ.CLI.Seagull.Commands.HerringGullCommand,
       "gull_with_herring",
       [],
       %{aliases_file: aliases_file_name, herring: "atlantic"},
       []}

    assert @subject.parse(["flying_gull", "--aliases-file", aliases_file_name]) ==
      {RabbitMQ.CLI.Seagull.Commands.HerringGullCommand,
       "flying_gull",
       ["fly"],
       %{aliases_file: aliases_file_name},
       []}

    assert @subject.parse(["garbage_gull", "--aliases-file", aliases_file_name]) ==
      {RabbitMQ.CLI.Seagull.Commands.HerringGullCommand,
       "garbage_gull",
       [],
       %{aliases_file: aliases_file_name, garbage: true},
       []}

    assert @subject.parse(["complex_gull", "--aliases-file", aliases_file_name]) ==
      {RabbitMQ.CLI.Seagull.Commands.HerringGullCommand,
       "complex_gull",
       ["eat"],
       %{aliases_file: aliases_file_name, garbage: true, herring: "pacific", formatter: "erlang"},
       []}

    assert @subject.parse(["invalid_gull", "--aliases-file", aliases_file_name]) ==
      {RabbitMQ.CLI.Seagull.Commands.HerringGullCommand,
       "invalid_gull",
       [],
       %{aliases_file: aliases_file_name},
       [{"--invalid", nil}]}

    assert @subject.parse(["unknown_gull", "--aliases-file", aliases_file_name]) ==
      {:no_command, "unknown_gull", [], %{aliases_file: aliases_file_name}, []}

    File.rm(aliases_file_name)


    assert capture_io(:stderr,
      fn ->
        assert @subject.parse(["larus_pacificus", "--aliases-file", aliases_file_name]) ==
          {:no_command, "larus_pacificus", [], %{aliases_file: aliases_file_name}, []}
      end) =~ "Error reading aliases file"

  end

end
