#import "common.typ": cetz, monotext, hex

#let c = (len, ..args) => (type: "C", len: len, ..args.named())
#let d = (len, label, ..args) => (type: "D", len: len, label: label, ..args.named())
#let e = (len, ..args) => (type: "E", len: len, ..args.named())
#let h = (len, ..args) => (type: "H", len: len, ..args.named())
#let l = (len, ..args) => (type: "L", len: len, ..args.named())
#let u = (len, ..args) => (type: "U", len: len, ..args.named())
#let x = (len, ..args) => (type: "X", len: len, ..args.named())
#let z = (len, ..args) => (type: "Z", len: len, ..args.named())

#let diagram = (..args, w_scale: 1.0, y_scale: 1.0, grid: false, fg: () => none) => {
  cetz.canvas(length: 0.7em, {
    import cetz.draw
    let x_slope = 0.15 * w_scale;
    let y_step = 2 * y_scale
    let y_h = 1.0 * y_scale
    let y_m = 0.5 * y_scale
    let y_l = 0.0 * y_scale
    draw.set-style(stroke: (thickness: 0.07em))

    let resolve_level = (prev_state, event) => if event.type == "C" {
      if prev_state.level == "H" {
        "L"
      } else if prev_state.level == "L" {
        "H"
      }
    } else if ("L", "H", "E").contains(event.type) {
      event.type
    } else if ("Z", "X", "D", "U").contains(event.type) {
      "M"
    }

    let draw_event = (prev_state, event, next_type) => {
      let x_start = if ("D", "U").contains(event.type) and prev_state.type != "" { x_slope } else { 0.0 }
      let x_end = if ("D", "U").contains(next_type) {
        event.len * w_scale + x_slope
      } else {
        event.len * w_scale
      }
      if event.type == "L" {
        if prev_state.level == "H" {
          draw.line((x_start, y_h), (x_start + x_slope, y_l), (x_end, y_l))
        } else if prev_state.level == "E" {
          draw.line((x_start, y_h), (x_start + x_slope, y_l))
          draw.line((x_start, y_l), (x_end, y_l))
        } else if prev_state.level == "M" {
          draw.line((x_start, y_m), (x_start + x_slope, y_l), (x_end, y_l))
        } else {
          draw.line((x_start, y_l), (x_end, y_l))
        }
      } else if event.type == "H" {
        if prev_state.level == "L" {
          draw.line((x_start, y_l), (x_start + x_slope, y_h), (x_end, y_h))
        } else if prev_state.level == "E" {
          draw.line((x_start, y_l), (x_start + x_slope, y_h))
          draw.line((x_start, y_h), (x_end, y_h))
        } else if prev_state.level == "M" {
          draw.line((x_start, y_m), (x_start + x_slope, y_h), (x_end, y_h))
        } else {
          draw.line((x_start, y_h), (x_end, y_h))
        }
      } else if event.type == "C" {
        if prev_state.level == "L" {
          draw.line((x_start, y_l), (x_start, y_scale), (x_end, y_scale))
        } else if prev_state.level == "H" {
          draw.line((x_start, y_scale), (x_start, y_l), (x_end, y_l))
        }
      } else if event.type == "E" {
        if prev_state.level == "L" {
          draw.line((x_start, y_l), (x_start + x_slope, y_h), (x_end, y_h))
        } else if prev_state.level == "M" {
          draw.line((x_start, y_m), (x_start + x_slope, y_h), (x_end, y_h))
        } else {
          draw.line((x_start, y_h), (x_end, y_h))
        }
        if prev_state.level == "H" {
          draw.line((x_start, y_h), (x_start + x_slope, y_l), (x_end, y_l))
        } else if prev_state.level == "M" {
          draw.line((x_start, y_m), (x_start + x_slope, y_l), (x_end, y_l))
        } else {
          draw.line((x_start, y_l), (x_end, y_l))
        }
      } else if event.type == "X" {
        let opacity = 100% - (if "opacity" in event { event.opacity } else { 100% })
        draw.line((x_start, y_m), (x_end, y_m), stroke: (paint: red.lighten(opacity)))
      } else if event.type == "Z" {
        let opacity = 100% - (if "opacity" in event { event.opacity } else { 100% })
        draw.line((x_start, y_m), (x_end, y_m), stroke: (paint: blue.lighten(opacity)))
      } else if event.type == "D" or event.type == "U" {
        let opacity = 100% - (if "opacity" in event { event.opacity } else { 100% })
        let fg = (if "stroke" in event { event.stroke } else { black }).lighten(opacity)
        let fill = if event.type == "U" { gray } else if "fill" in event { event.fill.lighten(opacity) } else { none }
        let left-open = prev_state.level == ""
        let right-open = next_type == ""
        if left-open and right-open {
          if fill != none {
            draw.rect((x_start, y_l), (x_end, y_h), stroke: none, fill: fill)
          }
          draw.line((x_start, y_h), (x_end, y_h), stroke: (paint: fg))
          draw.line((x_start, y_l), (x_end, y_l), stroke: (paint: fg))
        } else {
          let points = ()
          if left-open {
            points.push((x_start, y_h))
            points.push((x_end - x_slope, y_h))
            points.push((x_end, y_m))
            points.push((x_end - x_slope, y_l))
            points.push((x_start, y_l))
          } else if right-open {
            points.push((x_end, y_h))
            points.push((x_start + x_slope, y_h))
            points.push((x_start, y_m))
            points.push((x_start + x_slope, y_l))
            points.push((x_end, y_l))
          } else {
            points.push((x_start, y_m))
            points.push((x_start + x_slope, y_h))
            points.push((x_end - x_slope, y_h))
            points.push((x_end, y_m))
            points.push((x_end - x_slope, y_l))
            points.push((x_start + x_slope, y_l))
            points.push((x_start, y_m))
          }
          draw.line(..points, stroke: (paint: fg), fill: fill)
        }
        draw.anchor("center", (event.len * w_scale / 2.0, y_m))
        if "label" in event {
          draw.content("center", text(0.5em, fill: black.lighten(opacity), event.label))
        }
      }
      draw.translate((event.len * w_scale, 0))
    }
    let lanes = args.pos().rev()
    draw.group(name: "labels", {
      for i in range(0, lanes.len()) {
        let lane = lanes.at(i)
        draw.content((0, i * y_step + 0.5), anchor: "right", lane.label)
      }
    })
    draw.group(name: "diagram", ctx => {
      let (x, _, _) = cetz.coordinate.resolve(ctx, "labels.right")
      draw.translate((x + 1, 0))
      draw.group(ctx => {
        for i in range(0, lanes.len()) {
          let lane = lanes.at(i)
          draw.group(ctx => {
            draw.anchor("left", (0.0, y_l))
            let prev_state = (level: "", type: "")
            for i in range(lane.wave.len()) {
              let event = lane.wave.at(i)
              let next_type = if i + 1 < lane.wave.len() { lane.wave.at(i + 1).type } else { "" }
              draw_event(prev_state, event, next_type)
              prev_state.level = resolve_level(prev_state, event)
              prev_state.type = event.type
            }
            draw.anchor("right", (0.0, y_h))
            if grid {
              draw.on-layer(-1, {
                draw.grid("left", "right", step: (x: 0.5 * w_scale, y: 0.5 * y_scale), stroke: (paint: gray.lighten(60%), thickness: 0.01em))
              })
            }
          })
          draw.translate((0, y_step))
        }
      })
      fg()
    })
  })
}

