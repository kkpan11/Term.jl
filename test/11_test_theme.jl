import Term: Theme, set_theme, demo_theme

@testset "\e[34mtheme" begin
    io = PipeBuffer()
    show(io, MIME("text/plain"), Theme())  # coverage
    @test read(io, String) isa String

    theme = TERM_THEME[]
    @test set_theme(theme) == theme
end

@testset "Theme demo" begin
    newtheme = Theme(
        name                         = "default",
        docstring                    = "green",
        string                       = "red",
        type                         = "red",
        code                         = "bright_blue",
        multiline_code               = "bright_blue",
        symbol                       = "green",
        expression                   = "bright_Red",
        number                       = "grey",
        operator                     = "blue",
        func                         = "yellow",
        text                         = "white",
        text_accent                  = "greeen",
        emphasis                     = "blue  bold",
        emphasis_light               = "yellow",
        info                         = "#7cb0cf",
        debug                        = "#197fbd",
        warn                         = "green",
        error                        = "bold #d13f3f",
        logmsg                       = "#8abeff",
        tree_mid                     = "blue",
        tree_terminator              = "blue",
        tree_skip                    = "blue",
        tree_dash                    = "blue",
        tree_trunc                   = "blue",
        tree_pair                    = "red",
        tree_keys                    = "green",
        tree_max_leaf_width          = 22,
        repr_accent                  = "green",
        repr_name                    = "yellow",
        repr_type                    = "red",
        repr_values                  = "blue",
        repr_line                    = "dim red bold",
        repr_panel                   = "blue",
        repr_array_panel             = "green",
        repr_array_title             = "bold bright_blue",
        repr_array_text              = "red",
        err_accent                   = "yellow",
        er_bt                        = "white",
        err_btframe_panel            = "green",
        err_filepath                 = "grey",
        err_errmsg                   = "red",
        inspect_highlight            = "yellow",
        inspect_accent               = "green",
        progress_accent              = "green",
        progress_elapsedcol_default  = "black",
        progress_etacol_default      = "green",
        progress_spiner_default      = "bold red",
        progress_spinnerdone_default = "blue",
        dendo_title                  = "green",
        dendo_pretitle               = "red",
        dendo_leaves                 = "default dim",
        dendo_lines                  = "default dim",
        md_h1                        = "bold greem",
        md_h2                        = "bold blue underline",
        md_h3                        = "bold blue",
        md_h4                        = "bold red",
        md_h5                        = "bold green",
        md_h6                        = "bold red",
        md_latex                     = "yellow italic",
        md_code                      = "yellow italic",
        md_codeblock_bg              = "red",
        md_quote                     = "green",
        md_footnote                  = "red",
        md_table_header              = "bold blue",
        md_admonition_note           = "red",
        md_admonition_info           = "red",
        md_admonition_warning        = "green",
        md_admonition_danger         = "black",
        md_admonition_tip            = "bold white",
        tb_style                     = "red",
        tb_header                    = "bold grey",
        tb_columns                   = "green",
        tb_footer                    = "green",
        tb_box                       = :SIMPLE,
        line                         = "red",
        box                          = :HEAVY,
    )

    @compare_to_string(demo_theme(newtheme), "theme_demo")
end
