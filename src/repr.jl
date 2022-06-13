module Repr
using InteractiveUtils

import Term:
    truncate,
    escape_brackets,
    highlight,
    do_by_line,
    unescape_brackets,
    split_lines,
    term_theme

import ..Layout: vLine, rvstack, lvstack, Spacer, vstack, cvstack, hLine, pad
import ..Renderables: RenderableText, info, AbstractRenderable
import ..Consoles: console_width
import ..Panels: Panel, TextBox
import ..Style: apply_style
import ..Tprint: tprint
import ..Tables: Table
import ..TermMarkdown: parse_md

export @with_repr, termshow, install_term_repr

include("_repr.jl")
include("_inspect.jl")

function termshow(io::IO, obj)
    return print(
        io,
        Panel(
            repr_get_obj_fields_display(obj);
            fit = true,
            subtitle = escape_brackets(string(typeof(obj))),
            subtitle_justify = :right,
            width = 40,
            justify = :center,
            style = term_theme[].repr_panel_style,
            subtitle_style = term_theme[].repr_name_style,
        ),
    )
end

termshow(obj) = termshow(stdout, obj)

# ---------------------------------------------------------------------------- #
#                                     EXPR                                     #
# ---------------------------------------------------------------------------- #
function termshow(io::IO, e::Expr)
    content = repr_get_obj_fields_display(e)
    content =
        cvstack("{green}$(highlight(string(e))){/green}", hLine(content.measure.w), content)
    return print(
        io,
        Panel(
            content;
            fit = true,
            subtitle = escape_brackets(string(typeof(e))),
            subtitle_justify = :right,
            width = 40,
            justify = :center,
            style = term_theme[].repr_panel_style,
            subtitle_style = term_theme[].repr_name_style,
        ),
    )
end

# ---------------------------------------------------------------------------- #
#                                  DICTIONARY                                  #
# ---------------------------------------------------------------------------- #
function termshow(io::IO, obj::AbstractDict)
    short_string(x) = truncate(string(x), 30)
    # prepare text renderables
    k =
        RenderableText.(
            short_string.(keys(obj));
            style = term_theme[].repr_accent_style * " bold",
        )
    ktypes =
        RenderableText.(
            map(k -> "{{" * short_string(typeof(k)) * "}}", collect(keys(obj)));
            style = term_theme[].repr_type_style * " dim",
        )
    vals =
        RenderableText.(
            short_string.(values(obj));
            style = term_theme[].repr_values_style * " bold",
        )
    vtypes =
        RenderableText.(
            map(k -> "{{" * short_string(typeof(k)) * "}}", collect(values(obj)));
            style = term_theme[].repr_type_style * " dim",
        )

    # trim if too many
    arrows = if length(k) > 10
        k, ktypes, vals, vtypes = k[1:10], ktypes[1:10], vals[1:10], vtypes[1:10]

        push!(k, RenderableText("⋮"; style = term_theme[].repr_accent_style))
        push!(ktypes, RenderableText("⋮"; style = term_theme[].repr_type_style * " dim"))
        push!(vals, RenderableText("⋮"; style = term_theme[].repr_values_style))
        push!(vtypes, RenderableText("⋮"; style = term_theme[].repr_type_style * " dim"))

        vstack(RenderableText.(repeat(["=>"], length(k) - 1); style = "red bold")...)
    else
        vstack(RenderableText.(repeat(["=>"], length(k)); style = "red bold")...)
    end

    # prepare other renderables
    space = Spacer(1, length(k))
    line = vLine(length(k); style = "dim #7e9dd9")

    _keys_renderables = cvstack(ktypes...) * line * space * cvstack(k...)
    _values_renderables = cvstack(vals...) * space * line * cvstack(vtypes...)

    return print(
        io,
        Panel(
            _keys_renderables * space * arrows * space * _values_renderables;
            fit = true,
            title = escape_brackets(string(typeof(obj))),
            title_justify = :left,
            width = 40,
            justify = :center,
            style = term_theme[].repr_panel_style,
            title_style = term_theme[].repr_name_style,
            padding = (2, 2, 1, 1),
            subtitle = "{bold white}$(length(keys(obj))){/bold white}{default} items{/default}",
            subtitle_justify = :right,
        ),
    )
end

# ---------------------------------------------------------------------------- #
#                                ABSTRACT ARRAYS                               #
# ---------------------------------------------------------------------------- #
termshow(io::IO, mtx::AbstractMatrix) = print(
    io,
    repr_panel(
        mtx,
        matrix2content(mtx),
        "{bold white}$(size(mtx, 1)) × $(size(mtx, 2)){/bold white}{default} {/default}",
    ),
)

termshow(io::IO, vec::Union{Tuple,AbstractVector}) = print(
    io,
    repr_panel(
        vec,
        vec2content(vec),
        "{bold white}$(length(vec)){/bold white}{default} items{/default}";
        justify = :left,
    ),
)

function termshow(io::IO, arr::AbstractArray)
    I0 = CartesianIndices(size(arr)[3:end])
    I = I0[1:min(10, length(I0))]

    panels::Vector{Union{Panel,Spacer}} = []
    for (n, i) in enumerate(I)
        i_string = join([string(i) for i in Tuple(i)], ", ")
        push!(
            panels,
            Panel(
                matrix2content(arr[:, :, i]; max_w = 60, max_items = 25, max_D = 5);
                subtitle = "[:, :, $i_string]",
                subtitle_justify = :right,
                width = 22,
                style = "dim yellow",
                subtitle_style = "default",
                title = "($n)",
                title_style = "dim bright_blue",
            ),
        )
        push!(panels, Spacer(1, 2))
    end

    if length(I0) > length(I)
        push!(
            panels,
            Panel(
                "{dim bright_blue bold underline}$(length(I0) - length(I)){/dim bright_blue bold underline}{dim bright_blue} frames omitted{/dim bright_blue}";
                width = panels[end - 1].measure.w,
                style = "dim yellow",
            ),
        )
    end

    return print(
        io,
        repr_panel(
            arr,
            vstack(panels...),
            "{white}" * join(string.(size(arr)), " × ") * "{/white}",
        ),
    )
end

function termshow(io::IO, obj::DataType)
    ts = term_theme[].repr_type_style
    field_names = apply_style.(string.(fieldnames(obj)), term_theme[].repr_accent_style)
    field_types = apply_style.(map(f -> "::" * string(f), obj.types), ts)

    line = vLine(length(field_names); style = term_theme[].repr_name_style)
    space = Spacer(1, length(field_names))
    fields = rvstack(field_names...) * space * lvstack(string.(field_types)...)

    type_name = apply_style(string(obj), term_theme[].repr_name_style * " bold")
    sup = supertypes(obj)[2]
    type_name *= " {bright_blue dim}<: $sup{/bright_blue dim}"
    content =
        "    " * repr_panel(
            nothing,
            string(type_name / ("  " * line * fields)),
            nothing;
            fit = false,
            width = min(console_width() - 5, 80),
            justify = :center,
        )

    # get docstring
    doc, _ = get_docstring(obj)
    doc = parse_md(doc; width = min(100, console_width()))
    doc = split_lines(doc)
    if length(doc) > 100
        doc = [
            doc[1:min(100, length(doc))]...,
            "{dim bright_blue}$(length(doc)-100) lines omitted...{/dim bright_blue}",
        ]
    end
    doc = join(doc, "\n")

    print(io, content)
    print(io, hLine(console_width(), "Docstring"; style = "green dim", box = :HEAVY))
    tprint(io, doc)
end

function termshow(io::IO, fun::Function)
    # get methods
    _methods = split_lines(string(methods(fun)))
    N = length(_methods)

    _methods = length(_methods) > 1 ? _methods[2:min(11, N)] : []
    _methods = map(m -> join(split(join(split(m, "]")[2:end]), " in ")[1]), _methods)
    _methods = map(
        m -> replace(
            m,
            string(fun) => "{bold #a5c6d9}$(string(fun)){/bold #a5c6d9}";
            count = 1,
        ),
        _methods,
    )
    counts = RenderableText.("(" .* string.(1:length(_methods)) .* ") "; style = "bold dim")
    length(_methods) < N - 1 && push!(
        _methods,
        "\n{bold dim bright_blue}$(N - length(_methods)-1){/bold dim bright_blue}{dim bright_blue} methods omitted...{/dim bright_blue}",
    )
    methods_contents = if N > 1
        rvstack(counts...) * lvstack(RenderableText.(highlight.(_methods))...)
    else
        split_lines(string(methods(fun)))[1]
    end

    panel =
        "       " * repr_panel(
            nothing,
            methods_contents,
            "{white bold}$(N-1){/white bold} methods",
            title = "Function: {bold bright_blue}$(string(fun)){/bold bright_blue}",
            width = console_width() - 12,
        )

    # get docstring 
    doc, _ = get_docstring(fun)
    doc = parse_md(doc; width = console_width() - 8)
    doc = split_lines(doc)
    if length(doc) > 100
        doc = [
            doc[1:min(100, length(doc))]...,
            "{dim bright_blue}$(length(doc)-100) lines omitted...{/dim bright_blue}",
        ]
    end
    print(io, panel)
    print(io, hLine(console_width(), "Docstring"; style = "green dim", box = :HEAVY))
    print(io, "   " * RenderableText(join(doc, "\n"); width = console_width() - 8))
end

# ---------------------------------------------------------------------------- #
#                                 INSTALL REPR                                 #
# ---------------------------------------------------------------------------- #
function install_term_repr()
    @eval begin
        import Term: termshow

        Base.show(io::IO, ::MIME"text/plain", num::Number) =
            tprint(io, string(num); highlight = true)

        Base.show(io::IO, num::Number) = tprint(io, string(num); highlight = true)

        Base.show(io::IO, ::MIME"text/plain", obj::AbstractDict) = termshow(io, obj)

        Base.show(io::IO, ::MIME"text/plain", obj::Union{AbstractArray,AbstractMatrix}) =
            termshow(io, obj)

        Base.show(io::IO, ::MIME"text/plain", fun::Function) = termshow(io, fun)

        Base.show(io::IO, ::MIME"text/plain", obj::DataType) = termshow(io, obj)

        Base.show(io::IO, ::MIME"text/plain", expr::Expr) = termshow(io, expr)
    end
end

# ---------------------------------------------------------------------------- #
#                                   WITH REPR                                  #
# ---------------------------------------------------------------------------- #

"""
    with_repr(typedef::Expr)

Function for the macro @with_repr which creates a `Base.show` method for a type.

The `show` method shows the field names/types for the 
type and the values of the fields.

# Example
```
@with_repr struct TestStruct2
    x::Int
    name::String
    y
end
```
"""
function with_repr(typedef::Expr)
    tn = typename(typedef) # the name of the type
    showfn = :(Base.show(io::IO, ::MIME"text/plain", obj::$tn) = termshow(io, obj))

    quote
        $typedef
        $showfn
    end
end

"""
with_repr(typedef::Expr)

Function for the macro @with_repr which creates a `Base.show` method for a type.

The `show` method shows the field names/types for the 
type and the values of the fields.

# Example
```
@with_repr struct TestStruct2
x::Int
name::String
y
end
```
"""
macro with_repr(typedef)
    return esc(with_repr(typedef))
end

end