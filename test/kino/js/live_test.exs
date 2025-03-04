defmodule Kino.JS.LiveTest do
  use Kino.LivebookCase, async: true

  alias Kino.TestModules.LiveCounter

  # Integration tests covering callback paths
  describe "LiveCounter" do
    test "handle_connect/1" do
      kino = LiveCounter.new(0)
      LiveCounter.bump(kino, 1)
      count = connect(kino)
      assert count == 1
    end

    test "handle_cast/2 with event broadcast" do
      kino = LiveCounter.new(0)
      LiveCounter.bump(kino, 2)
      assert_broadcast_event(kino, "bump", %{by: 2})
    end

    test "handle_call/3" do
      kino = LiveCounter.new(0)
      LiveCounter.bump(kino, 1)
      count = LiveCounter.read(kino)
      assert count == 1
    end

    test "handle_call/3 :noreply" do
      kino = LiveCounter.new(0)
      LiveCounter.bump(kino, 1)
      count = LiveCounter.read_after(kino, 0)
      assert count == 1
    end

    test "handle_info/2" do
      kino = LiveCounter.new(0)
      send(kino.pid, {:ping, self()})
      assert_receive :pong
    end

    test "handle_event/3" do
      kino = LiveCounter.new(0)
      # Simulate a client event
      push_event(kino, "bump", %{"by" => 2})
      count = LiveCounter.read(kino)
      assert count == 2
    end

    test "handle_event/3 with send event" do
      kino = LiveCounter.new(0)
      # Simulate a client event
      _ = connect(kino)
      push_event(kino, "ping", %{})
      assert_send_event(kino, "pong", %{})
    end
  end

  test "server ping" do
    %{ref: ref} = kino = LiveCounter.new(0)
    send(kino.pid, {:ping, self(), :metadata, %{ref: ref}})
    assert_receive {:pong, :metadata, %{ref: ^ref}}
  end

  test "monitor/1" do
    %{pid: pid} = kino = LiveCounter.new(0)
    ref = Kino.JS.Live.monitor(kino)
    assert is_reference(ref)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, :process, ^pid, :killed}
  end
end
