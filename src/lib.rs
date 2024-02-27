#[macro_use]
extern crate rocket;

use rocket::Build;

mod routes;
mod test;

pub fn rocket_server() -> rocket::Rocket<Build> {
    rocket::build()
        .mount("/", routes![routes::index, routes::hello])
        .mount("/ping", routes![routes::ping])
}
