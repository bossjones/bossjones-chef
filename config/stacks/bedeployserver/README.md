`deployserver`
=====================

A deploy server with 3 seperate application instances

To use this VM configuration in your own project:

* Copy the `VagrantFile` and `vagrant` directory to the root of your source
  tree.
* Change the `appserver.vm.box_url` and `elasticsearch.vm.box_url` settings in
  `VagrantFile` to point to a URLs containing the respective box images.
* `vagrant up` in your source tree root.
* Repurpose `README.vagrant.md` into your project documentation.
