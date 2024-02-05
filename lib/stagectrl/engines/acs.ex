defmodule Stagectrl.Protocol.Acs do
  @moduledoc """
  Implementation of the low-level SpiiPlus protocol(s),
  along with some basic helper methods.

  See `Engine.Acs` for a higher-level interface built on
  top of this.
  """

  @max_msg_len 1023

  @doc """
  Decode message from host.
  """
  
  # Decode prompt reply.
  def decode(<<0xE9,id::8>>) do
    {:ok, id, "", false}
  end

  # Decode error message.
  def decode(<<0xE3,id::8,0x06,0x00,"?",code::binary-4,0xD,0xE6>>) do
    {:error, id, code, 0}
  end

  # Decode error message with checksum.
  def decode(<<0xE3,id::8,0x06,0x00,"?",code::binary-4,0xD,0xE6,csum::32>>) do
    {:error, id, code, 0}
  end

  # Decode reply.
  def decode(<<0xE3,id::8,length::little-15,last::1,body::binary-size(length),0xE6>>) do
    {:ok, id, body, last}
  end

  # Decode reply with checksum.
  def decode(<<0xE3,id::8,length::little-15,last::1,body::binary-size(length),0xE6,id,csum::32>>) do
    # @todo Maybe just check the checksum here?
    {:ok, id, body, last}
  end

  # Decode unsolicited message.
  def decode(<<0xE5,id::8,length::little-15,last::1,body::binary-size(length),0xE6>>) do
    # @todo Maybe just check the checksum here?
    {:ok, id, body, last}
  end

  # Decode unsolicited message with checksum.
  def decode(<<0xEE,id::8,length::little-15,last::1,body::binary-size(length),0xE6,csum::32>>) do
    # @todo Maybe just check the checksum here?
    {:ok, id, body, last}
  end

  # Decode non-safe format.
  def decode(<<body::binary>>) do
    {:no, 0, body, 0}
  end

  @doc """
  Decode body of message for a single 32-bit signed integer.
  """
  def decode_body_integer(body) do
    <<val::integer-signed-32>> = body
    val
  end

  @doc """
  Decode body of a message for a matrix of 32-bit signed integers.
  Only the column count need be given.
  """
  def decode_body_integers(body, columns, list \\ []) when is_integer(columns) do
    decode_body_integers(body, list)
    |> Enum.chunk_every(columns)
  end

  @doc """
  Decode body of message for a list of 32-bit signed integers.
  """
  def decode_body_integers(<<>>, list \\ []) when is_list(list), do: list
  def decode_body_integers(body, list) do
    <<val::integer-signed-32,rest::binary>> = body
    [ val | decode_body_int_list(rest) ]
  end

  @doc """
  Decode body of message for a single 64-bit floating point number.
  """
  def decode_body_real(body) do
    <<val::float-signed-64>> = body
    val
  end

  @doc """
  Decode body of a message for a matrix of 64-bit floating point numbers..
  Only the column count need be given.
  """
  def decode_body_reals(body, columns, list \\ []) when is_integer(columns) do
    decode_body_reals(body, list)
    |> Enum.chunk_every(columns)
  end

  @doc """
  Decode body of message for a list of 64-bit floating point numbers.
  """
  def decode_body_reals(<<>>, list \\ []), do: list
  def decode_body_reals(body, list) do
    <<val::float-signed-64,rest::binary>> = body
    [ val | decode_body_int_list(rest) ]
  end

  @doc """
  Encode message for ACS controller using "Safe Format".
  """
  
  def encode(id, body) do
    length = String.length(body)
    if length > @max_msg_len do
      last = 1  # extra long
      {body, rest} = String.split_at(body, @max_msg_len)
      msg = <<0xD3,id::8,length::little-15,last::1,body::binary-size(length),0xD6>>
      [msg] ++ encode(id, rest)  # id+1 ?
    else
      last = 0  # no more body
      msg = <<0xD3,id::8,length::little-15,last::1,body::binary-size(length),0xD6>>
      [msg]
    end
  end

  def encode_prompt(id) do
    <<0xD9,id::8>>
  end

  @doc """
  Encode command for binary reading of 32-bit signed integer data.
  """
  def encode_read_int(id, bufvar, from1, to1, from2, to2) do
    body = <<"%??",0x04,bufvar,"(#{from1},#{to1},#{from2},#{to2})">>
    encode(id, body)
  end

 def encode_read_int(id, bufvar, from1, to1) do
    encode_read_int(id, bufvar, from1, to1, 0, 0)
  end

  def encode_read_int(id, bufvar) do
    encode_read_int(id, bufvar, 0, 0, 0, 0)
  end

  @doc """
  Encode command for binary reading of 64-bit floating point data.
  """
  def encode_read_real(id, bufvar, from1, to1, from2, to2) do
    body = <<"%??",0x08,bufvar,"(#{from1},#{to1},#{from2},#{to2})">>
    encode(id, body)    
  end

  def encode_read_real(id, bufvar, from1, to1) do
    encode_read_real(id, bufvar, from1, to1, 0, 0)
  end

  def encode_read_real(id, bufvar) do
    encode_read_real(id, bufvar, 0, 0, 0, 0)
  end

  @doc """
  Calculate safe-format checksum given a body (without the `\r` ending).
  """
  def calc_checksum(body) do
    bodyr = "#{body}\r"
    # need to divide body up into 4-byte segments (u32) and 
    # sum them all up (assuming modulo 2^32).
    # @todo How?
  end
  
end
