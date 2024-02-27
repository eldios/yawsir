#[macro_use]
extern crate rocket;

use yawsir::rocket_server;

#[launch]
fn rocket() -> _ {
    rocket_server()
}
