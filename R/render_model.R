#' Render Molecule Model
#'
#' Automatically plots the molecule with a camera position and field of view that includes the full model.
#' For more control over the scene, pass the scene to `rayrender::render_scene()` and specify
#' the camera position manually. Note: spheres and cylinders in the scene are used to automatically
#' compute the field of view of the scene--adding additional sphere (e.g. with `rayrender::generate_ground()`)
#' will change this calculation. Use `rayrender::render_scene()` instead if this is a problem.
#'
#' @param scene `rayrender` scene of molecule model.
#' @param fov Default `NULL`, automatically calculated. Camera field of view.
#' @param angle Default `c(0,0,0)`. Degrees to rotate the model around the X, Y, and Z axes. If this
#' is a single number, it will be taken as the Y axis rotation.
#' @param order_rotation Default `c(1,2,3)`. What order to apply the rotations specified in `angle`.
#' @param lights Default `top`. If `none`, removes all lights. If `bottom`, lights scene with light
#' underneath model. If `both`, adds lights both above and below model.
#' @param lightintensity Default `80`. Light intensity.
#' @param ... Other arguments to pass to rayrender::render_scene()
#'
#' @return List giving the atom locations and the connections between atoms.
#' @import rayrender
#' @export
#'
#' @examples
#' # Generate a scene with caffeine molecule with just the atoms
#'\donttest{
#' get_example_molecule("caffeine") %>%
#'   read_sdf() %>%
#'   generate_full_scene() %>%
#'   render_model()
#'
#' #Light the example from below as well
#' get_example_molecule("caffeine") %>%
#'   read_sdf() %>%
#'   generate_full_scene() %>%
#'   render_model(lights = "both")
#'
#' #Generate a scene with penicillin, increasing the number of samples and the width/height
#' #for a higher quality render.
#' get_example_molecule("penicillin") %>%
#'   read_sdf() %>%
#'   generate_full_scene() %>%
#'   render_model(lights = "both", samples=400, width=800, height=800)
#'
#' #Rotate the molecule 30 degrees around the y axis, and the 30 degrees around the z axis
#' get_example_molecule("penicillin") %>%
#'   read_sdf() %>%
#'   generate_full_scene() %>%
#'   render_model(lights = "both", samples=400, width=800, height=800, angle=c(0,30,30))
#'
#' #Add a checkered plane underneath, using rayrender::add_object and rayrender::xz_rect().
#' #We also pass a value to `clamp_value` to minimize fireflies (bright spots).
#' library(rayrender)
#' get_example_molecule("skatole") %>%
#'   read_sdf() %>%
#'   generate_full_scene() %>%
#'   add_object(xz_rect(xwidth=1000,zwidth=1000,y=-4,
#'                      material=diffuse(color="#330000",checkercolor="#770000"))) %>%
#'   render_model(samples=400, width=800, height=800, clamp_value=10)
#'}
render_model = function(scene, fov = NULL, angle = c(0,0,0), order_rotation = c(1,2,3),
                        lights = "top", lightintensity = 80, ...) {
  if(length(angle) == 1) {
    angle = c(0,angle,0)
  }
  scene_model = scene[is.na(scene$lightintensity) &
                      (scene$shape == "cylinder" | scene$shape == "sphere"),]
  bbox_x = range(scene_model$x,na.rm=TRUE)
  bbox_y = range(scene_model$y,na.rm=TRUE)
  bbox_z = range(scene_model$z,na.rm=TRUE)
  spheresizes = scene[(scene$shape == "sphere" & scene$type != "light"),4]
  if(length(spheresizes) > 0) {
    max_sphere_radii = max(spheresizes,na.rm=TRUE)
  } else {
    max_sphere_radii = 0.5
  }

  widest = max(c(abs(bbox_x),abs(bbox_y),abs(bbox_z)))
  offset_dist = widest + widest/5 + max_sphere_radii
  if(is.null(fov)) {
    fov = atan2(widest+widest/5 + max_sphere_radii, widest*5)/pi*180*2
  }
  if(any(angle != 0)) {
    scene = group_objects(scene, group_angle = angle, group_order_rotation = order_rotation)
  }
  if(lights != "none") {
    if (lights == "top") {
      light = sphere(x=offset_dist*2,y=offset_dist*2,z=offset_dist*2,
                        radius = widest/2,
                        material = light(intensity=lightintensity)) %>%
        add_object(sphere(x=-offset_dist*2,y=offset_dist*2,z=-offset_dist*2,
                          radius = widest/2,
                          material = light(intensity=lightintensity)))
    } else {
      light = (sphere(x=offset_dist*2,y=offset_dist*2,z=offset_dist*2,
                      radius = widest/2,
                      material = light(intensity=lightintensity))) %>%
        add_object(sphere(x=-offset_dist*2,y=offset_dist*2,z=-offset_dist*2,
                          radius = widest/2,
                          material = light(intensity=lightintensity))) %>%
        add_object(sphere(y=-offset_dist*4,
                          radius=widest/2,
                          material = light(intensity=lightintensity)))
    }
    scene = scene %>%
      add_object(light)

  }
  render_scene(scene = scene,
               fov = fov, lookfrom = c(0,0,widest*5), ...)
}
