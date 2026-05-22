extends GutTest

func before_all():
	gut.p("Starting Input Driver Tests...")

func after_all():
	gut.p("Finished Input Driver Tests.")

func test_sanity_check():
	assert_eq(1, 1, "Math should work")

func test_plugin_manifest_structure():
	var manifest_path = "res://../plugin.cfg"
	assert_true(FileAccess.file_exists(manifest_path), "plugin.cfg should exist at the repo root")

	var config = ConfigFile.new()
	assert_eq(config.load(manifest_path), OK, "plugin.cfg should load")
	assert_true(config.get_value("plugin", "name", "") != "", "plugin name should be set")
