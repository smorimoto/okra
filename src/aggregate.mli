(*
 * Copyright (c) 2021 Magnus Skjegstad
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

exception No_time_found of string
exception Multiple_time_entries of string
exception Invalid_time of string
exception No_work_found of string
exception No_KR_ID_found of string
exception No_title_found of string

type t = {
  counter : int;
  project : string;
  objective : string;
  kr_title : string;
  kr_id : string;
  time_entries : string list;
  time_per_engineer : (string, float) Hashtbl.t;
  work : string list;
}
(** TODO: make it abstract *)

val compare : t -> t -> int

module Weekly : sig
  type elt
  type t = elt list list
  type table = (string, t) Hashtbl.t
end

val process :
  ?ignore_sections:string list ->
  ?include_sections:string list ->
  (string * string) list Omd.block list ->
  Weekly.table
(** Process markdown data from omd. Optionally [ignore_sections] can be used to
    ignore specific sections, or [include_sections] can be used to only process
    specific sections. *)

val of_weekly : Weekly.t -> t

val by_engineer :
  ?include_krs:string list -> Weekly.table -> (string, float) Hashtbl.t
