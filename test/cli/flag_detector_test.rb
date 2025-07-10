# frozen_string_literal: true

require "test_helper"

class FlagDetectorTest < Minitest::Test
  def test_has_help_flag_returns_true_for_help_flag
    detector = create_detector(["--help"])
    assert detector.has_help_flag?
  end

  def test_has_help_flag_returns_true_for_h_flag
    detector = create_detector(["-h"])
    assert detector.has_help_flag?
  end

  def test_has_help_flag_returns_true_for_empty_args
    detector = create_detector([])
    assert detector.has_help_flag?
  end

  def test_has_help_flag_returns_false_for_normal_command
    detector = create_detector(["analyze", "file.rb"])
    refute detector.has_help_flag?
  end

  def test_has_version_flag_returns_true_when_present
    detector = create_detector(["--version"])
    assert detector.has_version_flag?
  end

  def test_has_version_flag_returns_false_when_absent
    detector = create_detector(["analyze", "file.rb"])
    refute detector.has_version_flag?
  end

  def test_has_directory_flag_returns_true_when_present
    detector = create_detector(["analyze", "--directory", "app/"])
    assert detector.has_directory_flag?
  end

  def test_has_directory_flag_returns_false_when_absent
    detector = create_detector(["analyze", "file.rb"])
    refute detector.has_directory_flag?
  end

  def test_has_stats_flag_returns_true_for_stats_flag
    detector = create_detector(["analyze", "file.rb", "--stats"])
    assert detector.has_stats_flag?
  end

  def test_has_stats_flag_returns_true_for_s_flag
    detector = create_detector(["analyze", "file.rb", "-s"])
    assert detector.has_stats_flag?
  end

  def test_has_stats_flag_returns_false_when_absent
    detector = create_detector(["analyze", "file.rb"])
    refute detector.has_stats_flag?
  end

  def test_has_circular_flag_returns_true_for_circular_flag
    detector = create_detector(["analyze", "file.rb", "--circular"])
    assert detector.has_circular_flag?
  end

  def test_has_circular_flag_returns_true_for_c_flag
    detector = create_detector(["analyze", "file.rb", "-c"])
    assert detector.has_circular_flag?
  end

  def test_has_circular_flag_returns_false_when_absent
    detector = create_detector(["analyze", "file.rb"])
    refute detector.has_circular_flag?
  end

  def test_has_depth_flag_returns_true_for_depth_flag
    detector = create_detector(["analyze", "file.rb", "--depth"])
    assert detector.has_depth_flag?
  end

  def test_has_depth_flag_returns_true_for_d_flag
    detector = create_detector(["analyze", "file.rb", "-d"])
    assert detector.has_depth_flag?
  end

  def test_has_depth_flag_returns_false_when_absent
    detector = create_detector(["analyze", "file.rb"])
    refute detector.has_depth_flag?
  end

  def test_has_any_flag_returns_true_when_any_present
    detector = create_detector(["analyze", "file.rb", "--stats"])
    assert detector.has_any_flag?("--format", "--stats", "--output")
  end

  def test_has_any_flag_returns_false_when_none_present
    detector = create_detector(["analyze", "file.rb"])
    refute detector.has_any_flag?("--format", "--stats", "--output")
  end

  private

  def create_detector(args)
    RailsDependencyExplorer::CLI::FlagDetector.new(args)
  end
end
