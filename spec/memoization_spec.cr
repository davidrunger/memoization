require "spec"
require "../src/memoization"

private class ObjectWithMemoizedMethods
  getter times_method_1_called = 0
  getter times_method_2_called = 0
  getter times_method_3_called = 0
  getter times_method_4_called = 0
  getter times_method_5_called = 0
  getter times_method_6_called = 0
  getter times_method_7_called = 0

  memoize def method_1 : String
    @times_method_1_called += 1
    "method_1"
  end

  memoize def method_2 : Int32?
    @times_method_2_called += 1
    nil
  end

  memoize def method_3(arg_a : String, arg_b : String = "default-arg-b") : String
    @times_method_3_called += 1
    arg_a + ", " + arg_b
  end

  memoize def method_4? : Bool
    @times_method_4_called += 1
    true
  end

  memoize def method_5! : String
    @times_method_5_called += 1
    "Boom!"
  end

  memoize def method_6(for string : String) : String
    @times_method_6_called += 1
    string.upcase
  end

  def initials
    method_7
  end

  private memoize def method_7 : String
    @times_method_7_called += 1
    "TJ"
  end
end

describe "memoization" do
  it "only calls the method body once" do
    object = ObjectWithMemoizedMethods.new

    object.method_1.should eq "method_1"
    2.times { object.method_1.should eq("method_1") }
    object.times_method_1_called.should eq 1
  end

  it "can cache a nil result" do
    object = ObjectWithMemoizedMethods.new

    object.method_2.should be_nil
    2.times { object.method_2.should be_nil }
    object.times_method_2_called.should eq 1
  end

  it "caches based on argument equality" do
    object = ObjectWithMemoizedMethods.new

    object.method_3("arg-a", "arg-b").should eq("arg-a, arg-b")
    2.times { object.method_3("arg-a", "arg-b").should eq("arg-a, arg-b") }
    object.times_method_3_called.should eq 1

    object.method_3("arg-a", "arg-c").should eq("arg-a, arg-c")
    2.times { object.method_3("arg-a", "arg-c").should eq("arg-a, arg-c") }
    object.times_method_3_called.should eq 2
  end

  it "handles default arguments" do
    object = ObjectWithMemoizedMethods.new

    object.method_3("arg-a", "default-arg-b").should eq("arg-a, default-arg-b")
    object.method_3("arg-a", "default-arg-b").should eq("arg-a, default-arg-b")
    object.method_3("arg-a").should eq("arg-a, default-arg-b")
    object.times_method_3_called.should eq 1
  end

  it "handles calling with named arguments" do
    object = ObjectWithMemoizedMethods.new

    object.method_3("arg-a", "arg-b").should eq("arg-a, arg-b")
    object.method_3("arg-a", arg_b: "arg-b").should eq("arg-a, arg-b")
    object.method_3(arg_a: "arg-a", arg_b: "arg-b").should eq("arg-a, arg-b")
    object.method_3(arg_b: "arg-b", arg_a: "arg-a").should eq("arg-a, arg-b")
    object.times_method_3_called.should eq 1
  end

  it "holds on to result of previous calls" do
    object = ObjectWithMemoizedMethods.new

    object.method_3("arg-a", "arg-b").should eq("arg-a, arg-b")
    object.times_method_3_called.should eq 1
    object.method_3("arg-a", "arg-c").should eq("arg-a, arg-c")
    object.times_method_3_called.should eq 2
    object.method_3("arg-a", "arg-b").should eq("arg-a, arg-b")
    object.times_method_3_called.should eq 2
    object.method_3("arg-a", "arg-d").should eq("arg-a, arg-d")
    object.times_method_3_called.should eq 3
    object.method_3("arg-a", "arg-c").should eq("arg-a, arg-c")
    object.times_method_3_called.should eq 3
  end

  it "works with predicate methods" do
    object = ObjectWithMemoizedMethods.new

    object.method_4?.should eq(true)
    object.method_4?.should eq(true)
    object.method_4?.should eq(true)
    object.times_method_4_called.should eq(1)
  end

  it "Works with bang methods" do
    object = ObjectWithMemoizedMethods.new

    object.method_5!.should eq("Boom!")
    object.method_5!.should eq("Boom!")
    object.method_5!.should eq("Boom!")
    object.times_method_5_called.should eq(1)
  end

  it "calls uncached with predicate and bang methods" do
    object = ObjectWithMemoizedMethods.new

    object.method_4__uncached?.should eq(true)
    object.method_4__uncached?.should eq(true)
    object.method_4__uncached?.should eq(true)
    object.times_method_4_called.should eq(3)

    object.method_5__uncached!.should eq("Boom!")
    object.method_5__uncached!.should eq("Boom!")
    object.method_5__uncached!.should eq("Boom!")
    object.times_method_5_called.should eq(3)
  end

  it "allows for external arg names" do
    object = ObjectWithMemoizedMethods.new

    object.method_6("boom").should eq("BOOM")
    object.method_6(for: "memoize").should eq("MEMOIZE")
    object.times_method_6_called.should eq(2)

    object.method_6("boom").should eq("BOOM")
    object.method_6(for: "memoize").should eq("MEMOIZE")
    object.times_method_6_called.should eq(2)
  end

  it "allows memoizing private methods" do
    object = ObjectWithMemoizedMethods.new

    object.initials.should eq("TJ")
    object.times_method_7_called.should eq(1)
    object.initials.should eq("TJ")
    object.times_method_7_called.should eq(1)
  end
end
