defmodule StagectrlTest.Protocol.Acs do
  use ExUnit.Case
  alias Stagectrl.Protocol
  doctest Stagectrl.Protocol.Acs

  test "decode prompt reply" do
    assert Protocol.Acs.decode(<<0xE9,0x01>>) == {:ok, 1, "", false}
    assert Protocol.Acs.decode(<<0xE9,0xCC>>) == {:ok, 0xCC, "", false}
  end

  test "decode reply" do
    assert Protocol.Acs.decode(<<0xE3,0x06,0x4,0x00,"|Q",0xF6,"I",0xE6>>) == {:ok, 6, <<"|Q",0xF6,"I">>, 0}
  end

  test "decode error" do
    assert Protocol.Acs.decode(<<0xE3,0x02,0x06,0x00,"?3079\r",0xE6>>) == {:error, 2, "3079", 0}
  end
end
