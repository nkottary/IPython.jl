function envinfo(io::IO = STDOUT; verbosity::Int = 1)
    if verbosity > 0
        versioninfo(io, verbosity > 1)
        println(io)
    end
    for ex in [:(PyCall.pyprogramname),
               :(PyCall.pyversion),
               :(PyCall.libpython),
               :(PyCall.conda),
               :(pyversion("IPython")),
               :(pyversion("julia")),
               ]
        Base.show_unquoted(io, ex)
        println(io, " = ", eval(ex))
    end
    nothing
end

function pkg_resources_version(name)
    pkg_resources = try
        pyimport("pkg_resources")
    catch err
        if ! (err isa PyCall.PyError)
            rethrow()
        end
        return
    end
    return pkg_resources[:get_distribution](name)[:version]
end

function _pyversion(name)
    package = try
        pyimport(name)
    catch err
        if ! (err isa PyCall.PyError)
            rethrow()
        end
        return
    end
    try
        return package[:__version__]
    catch err
        if ! (err isa KeyError)
            rethrow()
        end
    end
end

function pyversion(name)
    version = pkg_resources_version(name)
    if version !== nothing
        return version
    end
    return _pyversion(name)
end


conda_packages = ("ipython", "pytest")

function prefer_condajl(package)
    PyCall.conda && package in conda_packages
end

function prefer_pip(package)
    package in (conda_packages..., "julia")
end

function install_dependency(package; dry_run=false)
    if prefer_condajl(package)
        info("Installing $package via Conda.jl")
        info("Conda.add($package)")
        if ! dry_run
            Conda.add(package)
        end
    elseif prefer_pip(package)
        info("Installing $package for $(PyCall.pyprogramname)")
        pip_install = `$(PyCall.pyprogramname) -m pip install $package`
        info(pip_install)
        if ! dry_run
            run(pip_install)
        end
    else
        warn("Installing $package not supported.")
    end
end


function test_replhelper()
    command = `$(PyCall.pyprogramname) -m pytest`
    info(command)
    cd(@__DIR__) do
        run(command)
    end
end