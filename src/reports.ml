(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2021 Patrick Ferris <pf341@patricoferris.com>
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

open Aggregate

let pp_days ppf d =
  let d = floor (d *. 2.0) /. 2. in
  if d = 1. then Fmt.string ppf "1 day"
  else if classify_float (fst (modf d)) = FP_zero then Fmt.pf ppf "%.0f days" d
  else Fmt.pf ppf "%.1f days" d

let line ppf fmt = Fmt.pf ppf ("@[<h>" ^^ fmt ^^ "@]")

let pp_engineer ~time ppf (e, d) =
  if time then Fmt.pf ppf "@%s (%a)" e pp_days d else Fmt.pf ppf "@%s" e

let pp_engineers ~time ppf entries =
  let entries = List.of_seq (Hashtbl.to_seq entries) in
  let entries = List.sort (fun (x, _) (y, _) -> String.compare x y) entries in
  line ppf "%a" Fmt.(list ~sep:(unit ", ") (pp_engineer ~time)) entries

let pp ?(include_krs = []) ?(show_time = true) ?(show_time_calc = true)
    ?(show_engineers = true) ppf okrs =
  let v =
    List.map Aggregate.of_weekly (List.of_seq (Hashtbl.to_seq_values okrs))
  in
  let uppercase_include_krs = List.map String.uppercase_ascii include_krs in
  let c_project = ref "" in
  let c_objective = ref "" in
  let c_kr_id = ref "" in
  let c_kr_title = ref "" in
  List.iter
    (fun e ->
      (* only proceed if include_krs is empty or has a match *)
      if List.length include_krs = 0 || List.mem e.kr_id uppercase_include_krs
      then (
        if e.project <> !c_project then (
          c_project := e.project;
          line ppf "# %s@.@." e.project);
        if e.objective <> !c_objective then (
          c_objective := e.objective;
          line ppf "## %s@.@." e.objective);
        if e.kr_id <> !c_kr_id || e.kr_title <> !c_kr_title then (
          c_kr_title := e.kr_title;
          c_kr_id := e.kr_id;
          line ppf "- %s (%s)@." e.kr_title e.kr_id);
        if show_engineers then
          if show_time then
            if show_time_calc then
              (* show time calc + engineers *)
              let pp_items ppf entries =
                List.iter (fun e -> line ppf "  - + %s@." e) entries
              in
              line ppf "%a  - = %a@." pp_items e.time_entries
                (pp_engineers ~time:true) e.time_per_engineer
            else
              (* show total time for each engineer *)
              line ppf "  - %a@." (pp_engineers ~time:true) e.time_per_engineer
          else
            line ppf "  - %a@." (pp_engineers ~time:false) e.time_per_engineer;
        Fmt.list ~sep:Fmt.cut
          (fun ppf s ->
            (* hack to align internal lines *)
            let lines = String.split_on_char '\n' s in
            (* remove the last '\n' *)
            let lines = List.rev (List.tl (List.rev lines)) in
            let lines = String.concat "\n    " lines in
            Fmt.pf ppf "@[<hov 4>  - %s@]" lines)
          ppf e.work)
      else () (* skip this KR *))
    (List.sort Aggregate.compare v)
