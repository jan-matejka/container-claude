####
TODO
####

``git clean -fdx`` deletes local, gitignored config files
===========================================================

The worktree root keeps two untracked, gitignored files that ``compose.yaml``
depends on: ``.env`` (variable substitution for the compose file, e.g.
``CLAUDE_REMOTE_PODMAN``/``CLAUDE_SSH_KEY``) and ``.git.container`` (a copy of
the worktree's ``.git`` file with the ``gitdir:`` pointer rewritten to the
container-side path, bind-mounted read-only over ``/app/.git`` so that
``git worktree``'s host-absolute admin paths resolve correctly from inside
the container).

``git clean -fdx`` removes both, because ``-x`` deliberately bypasses
``.gitignore``/``info/exclude``, and the only thing that survives ``-x`` is
the ``-e <pattern>`` flag -- which is per-invocation, not persisted anywhere.
Confirmed via ``git help -c`` that no ``clean.exclude``-style config key
exists to make this durable without a wrapper.

Current workaround: a git alias baking in the exclusions --
``git config alias.cleanall '!git clean -fdx -e .env -e .git.container'`` --
which works today but has to be remembered/re-applied per clone and doesn't
help if someone runs a bare ``git clean -fdx``.

Proposal: ``clean=false`` in ``.gitattributes``
==================================================

Extend ``git clean`` to consult ``.gitattributes`` -- already tracked,
already the mechanism ``export-ignore`` uses for ``git archive`` -- for a new
``clean`` attribute. Paths marked ``clean=false`` would be skipped by
``git clean`` even under ``-x``::

    .env             clean=false
    .git.container   clean=false

This declares the exclusion once, in a file that's committed and travels
with every clone/worktree, instead of in a personal alias or wrapper script.
Not implemented anywhere; would need a patch to git's ``builtin/clean.c``
(and realistically an upstream proposal, since neither a config key nor an
attribute for this exists today).

Proposal: git-derived interpolation variables in docker/compose
===================================================================

Separately, moving files like ``.git.container`` fully out of the worktree
(e.g. under ``~/.config/jm/claude/<worktree>/``) needs a *worktree-specific*
path injected into ``compose.yaml``'s variable interpolation. That value
can't be a literal default in the tracked file (it differs per
worktree/clone), and getting it into the environment without editing tracked
files otherwise requires either a wrapper script or direnv +
``COMPOSE_ENV_FILES`` -- both extra moving parts for what should be a couple
of built-in lookups.

Idea: docker/compose already computes some interpolation variables itself
(``COMPOSE_PROJECT_NAME`` from the containing directory name). Extend that
pattern with git-derived builtins -- e.g. ``${GIT_WORKTREE}``,
``${GIT_COMMON_DIR}`` -- populated automatically (via something like
``git rev-parse --show-toplevel``/``--git-common-dir``) whenever the project
directory sits inside a git repository. ``compose.yaml`` could then reference
these directly, with the file itself staying the single tracked source of
truth and no wrapper/direnv dependency.

Not implemented. Likely a harder sell upstream than the git-side proposal
above, since it's a narrow git-specific builtin rather than the more general
(and previously rejected, for reproducibility/security reasons) idea of
allowing arbitrary command substitution in compose interpolation.
