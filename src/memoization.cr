module Memoization
  macro memoize(method_def)
    {% raise "You must define a return type for memoized methods" if method_def.return_type.is_a?(Nop) %}
    {% raise "All arguments must have an explicit type restriction for memoized methods" if method_def.args.any? &.restriction.is_a?(Nop) %}

    {% special_ending = nil %}
    {% safe_method_name = method_def.name %}

    {%
      if method_def.name.ends_with?('?')
        special_ending = "?"
        safe_method_name = method_def.name.tr("?", "")
      elsif method_def.name.ends_with?('!')
        special_ending = "!"
        safe_method_name = method_def.name.tr("!", "")
      end
    %}

    {% if method_def.args.empty? %}
      @__memoized_{{safe_method_name}} : {{ method_def.return_type }} | UninitializedMemo = UninitializedMemo::INSTANCE
    {% else %}
      @__memoized_{{safe_method_name}} : Hash(
        Tuple(
          {% for arg in method_def.args %}
            {{ arg.restriction }},
          {% end %}
        ), {{ method_def.return_type }}
      ) = Hash(
        Tuple(
          {% for arg in method_def.args %}
            {{ arg.restriction }},
          {% end %}
        ), {{ method_def.return_type }}).new
    {% end %}

    def {{ safe_method_name }}__uncached{% if special_ending %}{{ special_ending.id }}{% end %}(
      {% for arg in method_def.args %}
        {% if arg.name == arg.internal_name %}
          {{ arg.name }} : {{ arg.restriction }},
        {% else %}
          {{ arg.name }} {{ arg.internal_name }} : {{ arg.restriction }},
        {% end %}
      {% end %}
    ) : {{ method_def.return_type }}
      {{ method_def.body }}
    end

    def {{ safe_method_name }}__tuple_cached{% if special_ending %}{{ special_ending.id }}{% end %}(
      {% for arg in method_def.args %}
        {% if arg.name == arg.internal_name %}
          {{ arg.name }} : {{ arg.restriction }},
        {% else %}
          {{ arg.name }} {{ arg.internal_name }} : {{ arg.restriction }},
        {% end %}
      {% end %}
    ) : {{ method_def.return_type }}
      {% if method_def.args.size > 0 %}
        key = { {% for arg in method_def.args %}{{ arg.internal_name }}{% unless arg == method_def.args.last %}, {% end %}{% end %} }
        if @__memoized_{{ safe_method_name }}.has_key?(key)
          @__memoized_{{ safe_method_name }}[key]
        else
          @__memoized_{{ safe_method_name }}[key] = {{ safe_method_name }}__uncached{% if special_ending %}{{ special_ending.id }}{% end %}(
            {% for arg in method_def.args %}
              {{arg.internal_name}},
            {% end %}
          )
        end
      {% else %}
        if (value = @__memoized_{{ safe_method_name }}).is_a?(UninitializedMemo)
          @__memoized_{{ safe_method_name }} = {{ safe_method_name }}__uncached{% if special_ending %}{{ special_ending.id }}{% end %}
        else
          value
        end
      {% end %}
    end

    def {{ method_def.name }}(
      {% for arg in method_def.args %}
        {% has_default = arg.default_value || arg.default_value == false || arg.default_value == nil %}
        {% if arg.name == arg.internal_name %}
          {{ arg.name }} : {{ arg.restriction }}{% if has_default %} = {{ arg.default_value }}{% end %},
        {% else %}
          {{ arg.name }} {{ arg.internal_name }} : {{ arg.restriction }}{% if has_default %} = {{ arg.default_value }}{% end %},
        {% end %}
      {% end %}
    ) : {{ method_def.return_type }}
      {{ safe_method_name }}__tuple_cached{% if special_ending %}{{ special_ending.id }}{% end %}(
        {% for arg in method_def.args %}
          {{arg.internal_name}},
        {% end %}
      )
    end
  end

  class UninitializedMemo
    INSTANCE = new
  end
end

class Object
  include ::Memoization
end
