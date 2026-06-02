(lang dune 3.23)

(name scribe)

(version 0.1.0)

(generate_opam_files true)

(source
 (github sambyeol/scribe))

(authors "Seokhyun Lee <gbvrcx@gmail.com>")

(maintainers "Seokhyun Lee <gbvrcx@gmail.com>")

(license MIT)

(documentation https://github.com/sambyeol/scribe)

(package
 (name scribe)
 (synopsis "Value-based structured logging for OCaml")
 (description "Scribe is a small structured logging library whose logger values carry their level, sink, and context.")
 (depends
  (ocaml (>= 4.14))
  (dune (>= 3.23))
  yojson
  (alcotest :with-test))
 (tags
  ("logging" "structured-logging" "json" "library")))
