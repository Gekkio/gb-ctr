#import "common.typ": cetz, monotext, hex

#let clock = (len, ..args) => (type: "C", len: len, ..args.named())
#let data = (len, label, ..args) => (type: "D", len: len, label: label, ..args.named())
#let either = (len, ..args) => (type: "E", len: len, ..args.named())
#let high = (len, ..args) => (type: "H", len: len, ..args.named())
#let low = (len, ..args) => (type: "L", len: len, ..args.named())
#let unknown = (len, ..args) => (type: "U", len: len, ..args.named())
#let undefined = (len, ..args) => (type: "X", len: len, ..args.named())
#let high_impedance = (len, ..args) => (type: "Z", len: len, ..args.named())

#let diagram = (..args, w_scale: 1.0, y_scale: 1.0, grid: false, fg: () => none) => {
  cetz.canvas(length: 0.7em, {
    import cetz.draw
    let x_slope = 0.15 * w_scale;
    let y_step = 2 * y_scale

    let y_level = (H: 1.0 * y_scale, L: 0.0 * y_scale, M: 0.5 * y_scale)
    draw.set-style(stroke: (thickness: 0.07em))

    let resolve_level = (prev_state, event) => if event.type == "C" {
      if prev_state.level == "L" { "H" } else { "L" }
    } else if ("L", "H", "E").contains(event.type) {
      event.type
    } else if ("Z", "X", "D", "U").contains(event.type) {
      "M"
    }

    let invert_level = (level) => if level == "L" { "H" }
      else if level == "H" { "L" }
      else { level }

    let draw_event = (prev_state, event, next_type) => {
      let opacity = 100% - (if "opacity" in event { event.opacity } else { 100% })
      let fg_paint = (if event.type == "X" { red }
        else if event.type == "Z" { blue }
        else { black }
      ).lighten(opacity)
      let fg_opts = (stroke: if "stroke" in event { event.stroke } else { (paint: fg_paint) })

      let x_start = if ("D", "U").contains(prev_state.type) { x_slope } else { 0.0 }
      let x_end = event.len * w_scale
      if event.type == "L" or event.type == "H" {
        let y = y_level.at(event.type)
        let y_invert = y_level.at(invert_level(event.type))
        if prev_state.level == event.type or prev_state.level == "" {
          draw.line((x_start, y), (x_end, y), ..fg_opts)
        } else if prev_state.level == "E" {
          draw.line((x_start, y_invert), (x_start + x_slope, y), ..fg_opts)
          draw.line((x_start, y), (x_end, y), ..fg_opts)
        } else if prev_state.level == "M" {
          draw.line((x_start, y_level.M), (x_start + x_slope, y), (x_end, y), ..fg_opts)
        } else if prev_state.level == invert_level(event.type) {
          draw.line((x_start, y_invert), (x_start + x_slope, y), (x_end, y), ..fg_opts)
        }
      } else if event.type == "C" {
        if prev_state.level == "L" or prev_state.level == "H" {
          let prev_y = y_level.at(prev_state.level)
          let y = y_level.at(invert_level(prev_state.level))
          draw.line((x_start, prev_y), (x_start, y), (x_end, y), ..fg_opts)
        } else if prev_state.level == "E" {
          draw.line((x_start, y_level.H), (x_start + x_slope, y_level.L), ..fg_opts)
          draw.line((x_start, y_level.L), (x_end, y_level.L), ..fg_opts)
        } else if prev_state.level == "M" {
          draw.line((x_start, y_level.M), (x_start + x_slope, y_level.L), (x_end, y_level.L), ..fg_opts)
        } else if prev_state.level == "" {
          draw.line((x_start, y_level.L), (x_end, y_level.L), ..fg_opts)
        }
      } else if event.type == "E" {
        if prev_state.level == "L" or prev_state.level == "M" {
          let y = y_level.at(prev_state.level)
          draw.line((x_start, y), (x_start + x_slope, y_level.H), (x_end, y_level.H), ..fg_opts)
        } else {
          draw.line((x_start, y_level.H), (x_end, y_level.H), ..fg_opts)
        }
        if prev_state.level == "H" or prev_state.level == "M" {
          let y = y_level.at(prev_state.level)
          draw.line((x_start, y), (x_start + x_slope, y_level.L), (x_end, y_level.L), ..fg_opts)
        } else {
          draw.line((x_start, y_level.L), (x_end, y_level.L), ..fg_opts)
        }
      } else if event.type == "X" or event.type == "Z" {
        if prev_state.level == "L" or prev_state.level == "H" {
          let y = y_level.at(prev_state.level)
          draw.line((x_start, y), (x_start + x_slope, y_level.M), (x_end, y_level.M), ..fg_opts)
        } else if prev_state.level == "M" or prev_state.level == "" {
          draw.line((x_start, y_level.M), (x_end, y_level.M), ..fg_opts)
        } else if prev_state.level == "E" {
          draw.line((x_start, y_level.H), (x_start + x_slope, y_level.M))
          draw.line((x_start, y_level.L), (x_start + x_slope, y_level.M))
          draw.line((x_start + x_slope, y_level.M), (x_end, y_level.M), ..fg_opts)
        }
      } else if event.type == "D" or event.type == "U" {
        let x_start = if ("X", "Z", "").contains(prev_state.type) { 0.0 } else { x_slope }
        let x_end = event.len * w_scale + x_slope
        let fill = if event.type == "U" { gray } else if "fill" in event { event.fill.lighten(opacity) } else { none }
        let left-open = prev_state.level == ""
        let right-open = next_type == ""
        if left-open and right-open {
          if fill != none {
            draw.rect((x_start, y_level.L), (x_end, y_level.H), stroke: none, fill: fill)
          }
          draw.line((x_start, y_level.H), (x_end, y_level.H), ..fg_opts)
          draw.line((x_start, y_level.L), (x_end, y_level.L), ..fg_opts)
        } else {
          if prev_state.level == "H" or prev_state.level == "E" {
            draw.line((0.0, y_level.H), (x_slope, y_level.M), ..fg_opts)
          }
          if prev_state.level == "L" or prev_state.level == "E" {
            draw.line((0.0, y_level.L), (x_slope, y_level.M), ..fg_opts)
          }
          let points = ()
          if left-open {
            points.push((x_start, y_level.H))
            points.push((x_end - x_slope, y_level.H))
            points.push((x_end, y_level.M))
            points.push((x_end - x_slope, y_level.L))
            points.push((x_start, y_level.L))
          } else if right-open {
            points.push((x_end, y_level.H))
            points.push((x_start + x_slope, y_level.H))
            points.push((x_start, y_level.M))
            points.push((x_start + x_slope, y_level.L))
            points.push((x_end, y_level.L))
          } else {
            points.push((x_start, y_level.M))
            points.push((x_start + x_slope, y_level.H))
            points.push((x_end - x_slope, y_level.H))
            points.push((x_end, y_level.M))
            points.push((x_end - x_slope, y_level.L))
            points.push((x_start + x_slope, y_level.L))
            points.push((x_start, y_level.M))
          }
          draw.line(..points, ..fg_opts, fill: fill)
        }
      }
      draw.anchor("center", ((x_end - x_start) / 2.0 + x_start, y_level.M))
      if "label" in event {
        draw.content("center", text(0.5em, fill: black.lighten(opacity), event.label))
      }
      draw.translate((event.len * w_scale, 0))
    }
    let lanes = args.pos().rev()
    draw.group(name: "labels", {
      for i in range(0, lanes.len()) {
        let lane = lanes.at(i)
        draw.content((0, i * y_step + 0.5), anchor: "east", lane.label)
      }
    })
    draw.group(name: "diagram", ctx => {
      let (ctx, east) = cetz.coordinate.resolve(ctx, "labels.east")
      let (x, _, _) = east;
      draw.translate((x + 1, 0))
      draw.group(ctx => {
        for i in range(0, lanes.len()) {
          let lane = lanes.at(i)
          draw.group(ctx => {
            draw.anchor("west", (0.0, y_level.L))
            let prev_state = (level: "", type: "")
            for i in range(lane.wave.len()) {
              let event = lane.wave.at(i)
              let next_type = if i + 1 < lane.wave.len() { lane.wave.at(i + 1).type } else { "" }
              draw_event(prev_state, event, next_type)
              prev_state.level = resolve_level(prev_state, event)
              prev_state.type = event.type
            }
            draw.anchor("east", (0.0, y_level.H))
            if grid {
              draw.on-layer(-1, {
                draw.grid("west", "east", step: (x: 0.5 * w_scale, y: 0.5 * y_scale), stroke: (paint: gray.lighten(60%), thickness: 0.01em))
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
