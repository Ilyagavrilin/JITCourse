out_dir := "out"
root := justfile_directory()

build lecture:
	mkdir -p {{out_dir}}
	typst compile --root {{root}} slides/{{lecture}}/main.typ {{out_dir}}/{{lecture}}.pdf

watch lecture:
	mkdir -p {{out_dir}}
	if grep -qi microsoft /proc/version 2>/dev/null; then \
	  watchexec --poll 200ms -r -- \
	    typst compile --root {{root}} slides/{{lecture}}/main.typ {{out_dir}}/{{lecture}}.pdf; \
	else \
	  typst watch --root {{root}} slides/{{lecture}}/main.typ {{out_dir}}/{{lecture}}.pdf; \
	fi

build-all:
	mkdir -p {{out_dir}}
	for d in slides/*; do \
	  name=$$(basename "$$d"); \
	  if [ -f "$$d/main.typ" ]; then \
	    typst compile --root {{root}} "$$d/main.typ" {{out_dir}}/"$$name".pdf; \
	  fi; \
	done

fmt:
	typstfmt -w theme/*.typ slides/*/*.typ
