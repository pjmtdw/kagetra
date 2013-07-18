require 'test/unit'
require_relative 'diff_match_patch'

class DiffTest < Test::Unit::TestCase
  Diff  = DiffPatchMatch::Diff
  Patch = DiffPatchMatch::Patch

  def setup
    @dmp = DiffPatchMatch.new
  end

  # Diff tests

  def test_diff_commonPrefix
    # Detect any common prefix.
    # Null case.
    assert_equal(0, @dmp.diff_commonPrefix('abc', 'xyz'))

    # Non-null case.
    assert_equal(4, @dmp.diff_commonPrefix('1234abcdef', '1234xyz'))

    # Whole case.
    assert_equal(4, @dmp.diff_commonPrefix('1234', '1234xyz'))
  end

  def test_diff_commonSuffix
    # Detect any common suffix.
    # Null case.
    assert_equal(0, @dmp.diff_commonSuffix('abc', 'xyz'))

    # Non-null case.
    assert_equal(4, @dmp.diff_commonSuffix('abcdef1234', 'xyz1234'))

    # Whole case.
    assert_equal(4, @dmp.diff_commonSuffix('1234', 'xyz1234'))
  end

  def test_diff_commonOverlap
    # Detect any suffix/prefix overlap.
    # Null case.
    assert_equal(0, @dmp.diff_commonOverlap('', 'abcd'))

    # Whole case.
    assert_equal(3, @dmp.diff_commonOverlap('abc', 'abcd'))

    # No overlap.
    assert_equal(0, @dmp.diff_commonOverlap('123456', 'abcd'))

    # Overlap.
    assert_equal(3, @dmp.diff_commonOverlap('123456xxx', 'xxxabcd'))
  end

  def test_diff_halfMatch
    # Detect a halfmatch.
    @dmp.diff_timeout = 1
    # No match.
    assert_equal(nil, @dmp.diff_halfMatch('1234567890', 'abcdef'))

    assert_equal(nil, @dmp.diff_halfMatch('12345', '23'))

    # Single Match.
    assert_equal(['12', '90', 'a', 'z', '345678'],
                 @dmp.diff_halfMatch('1234567890', 'a345678z'))

    assert_equal(['a', 'z', '12', '90', '345678'],
                 @dmp.diff_halfMatch('a345678z', '1234567890'))

    assert_equal(['abc', 'z', '1234', '0', '56789'],
                 @dmp.diff_halfMatch('abc56789z', '1234567890'))

    assert_equal(['a', 'xyz', '1', '7890', '23456'],
                 @dmp.diff_halfMatch('a23456xyz', '1234567890'))

    # Multiple Matches.
    assert_equal(['12123', '123121', 'a', 'z', '1234123451234'],
                 @dmp.diff_halfMatch('121231234123451234123121', 'a1234123451234z'))

    assert_equal(['', '-=-=-=-=-=', 'x', '', 'x-=-=-=-=-=-=-='],
                 @dmp.diff_halfMatch('x-=-=-=-=-=-=-=-=-=-=-=-=', 'xx-=-=-=-=-=-=-='))

    assert_equal(['-=-=-=-=-=', '', '', 'y', '-=-=-=-=-=-=-=y'],
                 @dmp.diff_halfMatch('-=-=-=-=-=-=-=-=-=-=-=-=y', '-=-=-=-=-=-=-=yy'))

    # Non-optimal halfmatch.
    # Optimal diff would be -q+x=H-i+e=lloHe+Hu=llo-Hew+y not -qHillo+x=HelloHe-w+Hulloy
    assert_equal(['qHillo', 'w', 'x', 'Hulloy', 'HelloHe'],
                 @dmp.diff_halfMatch('qHilloHelloHew', 'xHelloHeHulloy'))

    # Optimal no halfmatch.
    @dmp.diff_timeout = 0
    assert_equal(nil, @dmp.diff_halfMatch('qHilloHelloHew', 'xHelloHeHulloy'))
  end

  def test_diff_linesToChars
    # Convert lines down to characters.
    assert_equal(["\x01\x02\x01", "\x02\x01\x02", ['', "alpha\n", "beta\n"]],
                 @dmp.diff_linesToChars("alpha\nbeta\nalpha\n", "beta\nalpha\nbeta\n"))

    assert_equal(['', "\x01\x02\x03\x03", ['', "alpha\r\n", "beta\r\n", "\r\n"]],
                 @dmp.diff_linesToChars('', "alpha\r\nbeta\r\n\r\n\r\n"))

    assert_equal(["\x01", "\x02", ['', 'a', 'b']], @dmp.diff_linesToChars('a', 'b'))

    # More than 256 to reveal any 8-bit limitations.
    n = 300
    line_list = (1..n).map {|x| x.to_s + "\n" }
    char_list = (1..n).map {|x| x.chr(Encoding::UTF_8) }
    assert_equal(n, line_list.length)
    lines = line_list.join
    chars = char_list.join
    assert_equal(n, chars.length)
    line_list.unshift('')
    assert_equal([chars, '', line_list], @dmp.diff_linesToChars(lines, ''))
  end

  def test_diff_charsToLines
    # Convert chars up to lines.
    diffs = [Diff.new(:equal, "\x01\x02\x01"), Diff.new(:insert, "\x02\x01\x02")]
    @dmp.diff_charsToLines(diffs, ['', "alpha\n", "beta\n"])
    assert_equal([Diff.new(:equal, "alpha\nbeta\nalpha\n"),
                  Diff.new(:insert, "beta\nalpha\nbeta\n")],
                 diffs)
    # More than 256 to reveal any 8-bit limitations.
    n = 300
    line_list = (1..n).map {|x| x.to_s + "\n" }
    char_list = (1..n).map {|x| x.chr(Encoding::UTF_8) }
    assert_equal(n, line_list.length)
    lines = line_list.join
    chars = char_list.join
    assert_equal(n, chars.length)
    line_list.unshift('')

    diffs = [Diff.new(:delete, chars)]
    @dmp.diff_charsToLines(diffs, line_list)
    assert_equal([Diff.new(:delete, lines)], diffs)
  end

  def test_diff_cleanupMerge
    # Cleanup a messy diff.
    # Null case.
    diffs = []
    @dmp.diff_cleanupMerge(diffs)
    assert_equal([], diffs)

    # No change case.
    diffs = [Diff.new(:equal, 'a'), Diff.new(:delete, 'b'), Diff.new(:insert, 'c')]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal(
      [Diff.new(:equal, 'a'), Diff.new(:delete, 'b'), Diff.new(:insert, 'c')],
      diffs
    )

    # Merge equalities.
    diffs = [Diff.new(:equal, 'a'), Diff.new(:equal, 'b'), Diff.new(:equal, 'c')]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal([Diff.new(:equal, 'abc')], diffs)

    # Merge deletions.
    diffs = [Diff.new(:delete, 'a'), Diff.new(:delete, 'b'), Diff.new(:delete, 'c')]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal([Diff.new(:delete, 'abc')], diffs)

    # Merge insertions.
    diffs = [Diff.new(:insert, 'a'), Diff.new(:insert, 'b'), Diff.new(:insert, 'c')]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal([Diff.new(:insert, 'abc')], diffs)

    # Merge interweave.
    diffs = [
      Diff.new(:delete, 'a'), Diff.new(:insert, 'b'), Diff.new(:delete, 'c'),
      Diff.new(:insert, 'd'), Diff.new(:equal, 'e'), Diff.new(:equal, 'f')
    ]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal(
      [Diff.new(:delete, 'ac'), Diff.new(:insert, 'bd'), Diff.new(:equal, 'ef')],
      diffs
    )

    # Prefix and suffix detection.
    diffs = [Diff.new(:delete, 'a'), Diff.new(:insert, 'abc'), Diff.new(:delete, 'dc')]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal(
      [
        Diff.new(:equal, 'a'), Diff.new(:delete, 'd'), Diff.new(:insert, 'b'),
        Diff.new(:equal, 'c')
      ],
      diffs
    )

    # Prefix and suffix detection with equalities.
    diffs = [
      Diff.new(:equal, 'x'), Diff.new(:delete, 'a'), Diff.new(:insert, 'abc'),
      Diff.new(:delete, 'dc'), Diff.new(:equal, 'y')
    ]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal(
      [
        Diff.new(:equal, 'xa'), Diff.new(:delete, 'd'), Diff.new(:insert, 'b'),
        Diff.new(:equal, 'cy')
      ],
      diffs
    )

    # Slide edit left.
    diffs = [Diff.new(:equal, 'a'), Diff.new(:insert, 'ba'), Diff.new(:equal, 'c')]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal([Diff.new(:insert, 'ab'), Diff.new(:equal, 'ac')], diffs)

    # Slide edit right.
    diffs = [Diff.new(:equal, 'c'), Diff.new(:insert, 'ab'), Diff.new(:equal, 'a')]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal([Diff.new(:equal, 'ca'), Diff.new(:insert, 'ba')], diffs)

    # Slide edit left recursive.
    diffs = [
      Diff.new(:equal, 'a'), Diff.new(:delete, 'b'), Diff.new(:equal, 'c'),
      Diff.new(:delete, 'ac'), Diff.new(:equal, 'x')
    ]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal([Diff.new(:delete, 'abc'), Diff.new(:equal, 'acx')], diffs)

    # Slide edit right recursive.
    diffs = [
      Diff.new(:equal, 'x'), Diff.new(:delete, 'ca'), Diff.new(:equal, 'c'),
      Diff.new(:delete, 'b'), Diff.new(:equal, 'a')
    ]
    @dmp.diff_cleanupMerge(diffs)
    assert_equal([Diff.new(:equal, 'xca'), Diff.new(:delete, 'cba')], diffs)
  end

  def test_diff_cleanupSemanticLossless
    # Slide diffs to match logical boundaries.
    # Null case.
    diffs = []
    @dmp.diff_cleanupSemanticLossless(diffs)
    assert_equal([], diffs)

    # Blank lines.
    diffs = [
      Diff.new(:equal, "AAA\r\n\r\nBBB"), Diff.new(:insert, "\r\nDDD\r\n\r\nBBB"),
      Diff.new(:equal, "\r\nEEE")
    ]
    @dmp.diff_cleanupSemanticLossless(diffs)
    assert_equal(
      [
        Diff.new(:equal, "AAA\r\n\r\n"), Diff.new(:insert, "BBB\r\nDDD\r\n\r\n"),
        Diff.new(:equal, "BBB\r\nEEE")
      ],
      diffs
    )

    # Line boundaries.
    diffs = [
      Diff.new(:equal, "AAA\r\nBBB"), Diff.new(:insert, " DDD\r\nBBB"),
      Diff.new(:equal, " EEE")
    ]
    @dmp.diff_cleanupSemanticLossless(diffs)
    assert_equal(
      [
        Diff.new(:equal, "AAA\r\n"), Diff.new(:insert, "BBB DDD\r\n"),
        Diff.new(:equal, "BBB EEE")
      ],
      diffs
    )

    # Word boundaries.
    diffs = [
      Diff.new(:equal, 'The c'), Diff.new(:insert, 'ow and the c'),
      Diff.new(:equal, 'at.')
    ]
    @dmp.diff_cleanupSemanticLossless(diffs)
    assert_equal(
      [
        Diff.new(:equal, 'The '), Diff.new(:insert, 'cow and the '),
        Diff.new(:equal, 'cat.')
      ],
      diffs
    )

    # Alphanumeric boundaries.
    diffs = [
      Diff.new(:equal, 'The-c'), Diff.new(:insert, 'ow-and-the-c'),
      Diff.new(:equal, 'at.')
    ]
    @dmp.diff_cleanupSemanticLossless(diffs)
    assert_equal(
      [
        Diff.new(:equal, 'The-'), Diff.new(:insert, 'cow-and-the-'),
        Diff.new(:equal, 'cat.')
      ],
      diffs
    )

    # Hitting the start.
    diffs = [Diff.new(:equal, 'a'), Diff.new(:delete, 'a'), Diff.new(:equal, 'ax')]
    @dmp.diff_cleanupSemanticLossless(diffs)
    assert_equal([Diff.new(:delete, 'a'), Diff.new(:equal, 'aax')], diffs)

    # Hitting the end.
    diffs = [Diff.new(:equal, 'xa'), Diff.new(:delete, 'a'), Diff.new(:equal, 'a')]
    @dmp.diff_cleanupSemanticLossless(diffs)
    assert_equal([Diff.new(:equal, 'xaa'), Diff.new(:delete, 'a')], diffs)
  end


  def test_diff_cleanupSemantic
    # Cleanup semantically trivial equalities.
    # Null case.
    diffs = []
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal([], diffs)

    # No elimination #1.
    diffs = [
      Diff.new(:delete, 'ab'), Diff.new(:insert, 'cd'), Diff.new(:equal, '12'),
      Diff.new(:delete, 'e')
    ]
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal(
      [
        Diff.new(:delete, 'ab'), Diff.new(:insert, 'cd'), Diff.new(:equal, '12'),
        Diff.new(:delete, 'e')
      ],
      diffs
    )

    # No elimination #2.
    diffs = [
      Diff.new(:delete, 'abc'), Diff.new(:insert, 'ABC'), Diff.new(:equal, '1234'),
      Diff.new(:delete, 'wxyz')
    ]
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal(
      [
        Diff.new(:delete, 'abc'), Diff.new(:insert, 'ABC'), Diff.new(:equal, '1234'),
        Diff.new(:delete, 'wxyz')
      ],
      diffs
    )

    # Simple elimination.
    diffs = [Diff.new(:delete, 'a'), Diff.new(:equal, 'b'), Diff.new(:delete, 'c')]
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal([Diff.new(:delete, 'abc'), Diff.new(:insert, 'b')], diffs)

    # Backpass elimination.
    diffs = [
      Diff.new(:delete, 'ab'), Diff.new(:equal, 'cd'), Diff.new(:delete, 'e'),
      Diff.new(:equal, 'f'), Diff.new(:insert, 'g')
    ]
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal([Diff.new(:delete, 'abcdef'), Diff.new(:insert, 'cdfg')], diffs)

    # Multiple eliminations.
    diffs = [
      Diff.new(:insert, '1'), Diff.new(:equal, 'A'), Diff.new(:delete, 'B'),
      Diff.new(:insert, '2'), Diff.new(:equal, '_'), Diff.new(:insert, '1'),
      Diff.new(:equal, 'A'), Diff.new(:delete, 'B'), Diff.new(:insert, '2')
    ]
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal([Diff.new(:delete, 'AB_AB'), Diff.new(:insert, '1A2_1A2')], diffs)

    # Word boundaries.
    diffs = [
      Diff.new(:equal, 'The c'), Diff.new(:delete, 'ow and the c'),
      Diff.new(:equal, 'at.')
    ]
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal(
      [
        Diff.new(:equal, 'The '), Diff.new(:delete, 'cow and the '),
        Diff.new(:equal, 'cat.')
      ],
      diffs
    )

    # No overlap elimination.
    # TODO: This test is in the JavaScript test suite, yet it should fail...!?
    #diffs = [Diff.new(:delete, 'abcxx'), Diff.new(:insert, 'xxdef')]
    #@dmp.diff_cleanupSemantic(diffs)
    #assert_equal([Diff.new(:delete, 'abcxx'), Diff.new(:insert, 'xxdef')], diffs)

    # Overlap elimination.
    diffs = [Diff.new(:delete, 'abcxxx'), Diff.new(:insert, 'xxxdef')]
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal(
      [Diff.new(:delete, 'abc'), Diff.new(:equal, 'xxx'), Diff.new(:insert, 'def')],
      diffs
    )

    # Two overlap eliminations.
    diffs = [
      Diff.new(:delete, 'abcd1212'), Diff.new(:insert, '1212efghi'),
      Diff.new(:equal, '----'), Diff.new(:delete, 'A3'), Diff.new(:insert, '3BC')
    ]
    @dmp.diff_cleanupSemantic(diffs)
    assert_equal(
      [
        Diff.new(:delete, 'abcd'), Diff.new(:equal, '1212'), Diff.new(:insert, 'efghi'),
        Diff.new(:equal, '----'), Diff.new(:delete, 'A'), Diff.new(:equal, '3'),
        Diff.new(:insert, 'BC')
      ],
      diffs
    )
  end

  def test_diff_cleanupEfficiency
    # Cleanup operationally trivial equalities.
    @dmp.diff_editCost = 4
    # Null case.
    diffs = []
    @dmp.diff_cleanupEfficiency(diffs)
    assert_equal([], diffs)

    # No elimination.
    diffs = [Diff.new(:delete, 'ab'), Diff.new(:insert, '12'), Diff.new(:equal, 'wxyz'), Diff.new(:delete, 'cd'), Diff.new(:insert, '34')]
    @dmp.diff_cleanupEfficiency(diffs)
    assert_equal([Diff.new(:delete, 'ab'), Diff.new(:insert, '12'), Diff.new(:equal, 'wxyz'), Diff.new(:delete, 'cd'), Diff.new(:insert, '34')], diffs)

    # Four-edit elimination.
    diffs = [Diff.new(:delete, 'ab'), Diff.new(:insert, '12'), Diff.new(:equal, 'xyz'), Diff.new(:delete, 'cd'), Diff.new(:insert, '34')]
    @dmp.diff_cleanupEfficiency(diffs)
    assert_equal([Diff.new(:delete, 'abxyzcd'), Diff.new(:insert, '12xyz34')], diffs)

    # Three-edit elimination.
    diffs = [Diff.new(:insert, '12'), Diff.new(:equal, 'x'), Diff.new(:delete, 'cd'), Diff.new(:insert, '34')]
    @dmp.diff_cleanupEfficiency(diffs)
    assert_equal([Diff.new(:delete, 'xcd'), Diff.new(:insert, '12x34')], diffs)

    # Backpass elimination.
    diffs = [Diff.new(:delete, 'ab'), Diff.new(:insert, '12'), Diff.new(:equal, 'xy'), Diff.new(:insert, '34'), Diff.new(:equal, 'z'), Diff.new(:delete, 'cd'), Diff.new(:insert, '56')]
    @dmp.diff_cleanupEfficiency(diffs)
    assert_equal([Diff.new(:delete, 'abxyzcd'), Diff.new(:insert, '12xy34z56')], diffs)

    # High cost elimination.
    @dmp.diff_editCost = 5
    diffs = [Diff.new(:delete, 'ab'), Diff.new(:insert, '12'), Diff.new(:equal, 'wxyz'), Diff.new(:delete, 'cd'), Diff.new(:insert, '34')]
    @dmp.diff_cleanupEfficiency(diffs)
    assert_equal([Diff.new(:delete, 'abwxyzcd'), Diff.new(:insert, '12wxyz34')], diffs)
    @dmp.diff_editCost = 4
  end

  def test_diff_prettyHtml
    # Pretty print.
    diffs = [Diff.new(:equal, 'a\n'), Diff.new(:delete, '<B>b</B>'), Diff.new(:insert, 'c&d')]
    assert_equal(
      '<span>a&para;<br></span><del style="background:#ffe6e6;">&lt;B&gt;b&lt;/B&gt;</del><ins style="background:#e6ffe6;">c&amp;d</ins>',
      @dmp.diff_prettyHtml(diffs)
    )
  end

  def test_diff_text
    # Compute the source and destination texts.
    diffs = [
      Diff.new(:equal, 'jump'), Diff.new(:delete, 's'), Diff.new(:insert, 'ed'),
      Diff.new(:equal, ' over '), Diff.new(:delete, 'the'), Diff.new(:insert, 'a'),
      Diff.new(:equal, ' lazy')
    ]
    assert_equal('jumps over the lazy', @dmp.diff_text1(diffs))
    assert_equal('jumped over a lazy', @dmp.diff_text2(diffs))
  end

  def test_diff_delta
    # Convert a diff into delta string.
    diffs = [
      Diff.new(:equal, 'jump'), Diff.new(:delete, 's'), Diff.new(:insert, 'ed'),
      Diff.new(:equal, ' over '), Diff.new(:delete, 'the'), Diff.new(:insert, 'a'),
      Diff.new(:equal, ' lazy'), Diff.new(:insert, 'old dog')
    ]
    text1 = @dmp.diff_text1(diffs)
    assert_equal('jumps over the lazy', text1)

    delta = @dmp.diff_toDelta(diffs)
    assert_equal("=4\t-1\t+ed\t=6\t-3\t+a\t=5\t+old dog", delta)

    # Convert delta string into a diff.
    assert_equal(diffs, @dmp.diff_fromDelta(text1, delta))

    # Generates error (19 != 20).
    assert_raise ArgumentError do
      @dmp.diff_fromDelta(text1 + 'x', delta)
    end

    # Generates error (19 != 18).
    assert_raise ArgumentError do
      @dmp.diff_fromDelta(text1[1..-1], delta)
    end

    # Generates error (%c3%xy invalid Unicode).
    #assert_raise ArgumentError do
    #  @dmp.diff_fromDelta('', '+%c3%xy')
    #end

    # Test deltas with special characters.
    diffs = [
      Diff.new(:equal, "\u0680 \x00 \t %"), Diff.new(:delete, "\u0681 \x01 \n ^"),
      Diff.new(:insert, "\u0682 \x02 \\ |")
    ]
    text1 = @dmp.diff_text1(diffs)
    assert_equal("\u0680 \x00 \t %\u0681 \x01 \n ^", text1)

    delta = @dmp.diff_toDelta(diffs)
    assert_equal("=7\t-7\t+%DA%82 %02 %5C %7C", delta)

    # Convert delta string into a diff.
    assert_equal(diffs, @dmp.diff_fromDelta(text1, delta))

    # Verify pool of unchanged characters.
    diffs = [Diff.new(:insert, "A-Z a-z 0-9 - _ . ! ~ * \' ( )  / ? : @ & = + $ , # ")]
    text2 = @dmp.diff_text2(diffs)
    assert_equal("A-Z a-z 0-9 - _ . ! ~ * \' ( )  / ? : @ & = + $ , # ", text2)

    delta = @dmp.diff_toDelta(diffs)
    assert_equal("+A-Z a-z 0-9 - _ . ! ~ * \' ( )  / ? : @ & = + $ , # ", delta)

    # Convert delta string into a diff.
    assert_equal(diffs, @dmp.diff_fromDelta('', delta))
  end

  def test_diff_xIndex
    # Translate a location in text1 to text2.
    # Translation on equality.
    diffs = [Diff.new(:delete, 'a'), Diff.new(:insert, '1234'), Diff.new(:equal, 'xyz')]
    assert_equal(5, @dmp.diff_xIndex(diffs, 2))

    # Translation on deletion.
    diffs = [Diff.new(:equal, 'a'), Diff.new(:delete, '1234'), Diff.new(:equal, 'xyz')]
    assert_equal(1, @dmp.diff_xIndex(diffs, 3))
  end

  def test_diff_levenshtein
    # Levenshtein with trailing equality.
    diffs = [Diff.new(:delete, 'abc'), Diff.new(:insert, '1234'), Diff.new(:equal, 'xyz')]
    assert_equal(4, @dmp.diff_levenshtein(diffs))
    # Levenshtein with leading equality.
    diffs = [Diff.new(:equal, 'xyz'), Diff.new(:delete, 'abc'), Diff.new(:insert, '1234')]
    assert_equal(4, @dmp.diff_levenshtein(diffs))
    # Levenshtein with middle equality.
    diffs = [Diff.new(:delete, 'abc'), Diff.new(:equal, 'xyz'), Diff.new(:insert, '1234')]
    assert_equal(7, @dmp.diff_levenshtein(diffs))
  end

  def test_diff_bisect
    # Normal.
    a = 'cat'
    b = 'map'
    # Since the resulting diff hasn't been normalized, it would be ok if
    # the insertion and deletion pairs are swapped.
    # If the order changes, tweak this test as required.
    diffs = [
      Diff.new(:delete, 'c'), Diff.new(:insert, 'm'), Diff.new(:equal, 'a'),
      Diff.new(:delete, 't'), Diff.new(:insert, 'p')
    ]
    assert_equal(diffs, @dmp.diff_bisect(a, b, nil))

    # Timeout.
    assert_equal(
      [Diff.new(:delete, 'cat'), Diff.new(:insert, 'map')],
      @dmp.diff_bisect(a, b, Time.now - 1)
    )
  end

  def test_diff_main
    # Perform a trivial diff.
    # Null case.
    assert_equal([], @dmp.diff_main('', '', false))

    # Equality.
    assert_equal([Diff.new(:equal, 'abc')], @dmp.diff_main('abc', 'abc', false))

    # Simple insertion.
    assert_equal(
      [Diff.new(:equal, 'ab'), Diff.new(:insert, '123'), Diff.new(:equal, 'c')],
      @dmp.diff_main('abc', 'ab123c', false)
    )

    # Simple deletion.
    assert_equal(
      [Diff.new(:equal, 'a'), Diff.new(:delete, '123'), Diff.new(:equal, 'bc')],
      @dmp.diff_main('a123bc', 'abc', false)
    )

    # Two insertions.
    assert_equal(
      [
        Diff.new(:equal, 'a'), Diff.new(:insert, '123'), Diff.new(:equal, 'b'),
        Diff.new(:insert, '456'), Diff.new(:equal, 'c')
      ],
      @dmp.diff_main('abc', 'a123b456c', false)
    )

    # Two deletions.
    assert_equal(
      [
        Diff.new(:equal, 'a'), Diff.new(:delete, '123'), Diff.new(:equal, 'b'),
        Diff.new(:delete, '456'), Diff.new(:equal, 'c')
      ],
      @dmp.diff_main('a123b456c', 'abc', false)
    )

    # Perform a real diff.
    # Switch off the timeout.
    @dmp.diff_timeout = 0
    # Simple cases.
    assert_equal(
      [Diff.new(:delete, 'a'), Diff.new(:insert, 'b')],
      @dmp.diff_main('a', 'b', false)
    )

    assert_equal(
      [
        Diff.new(:delete, 'Apple'), Diff.new(:insert, 'Banana'),
        Diff.new(:equal, 's are a'), Diff.new(:insert, 'lso'),
        Diff.new(:equal, ' fruit.')
      ],
      @dmp.diff_main('Apples are a fruit.', 'Bananas are also fruit.', false)
    )

    assert_equal(
      [
        Diff.new(:delete, 'a'), Diff.new(:insert, "\u0680"), Diff.new(:equal, 'x'),
        Diff.new(:delete, "\t"), Diff.new(:insert, "\0")
      ],
      @dmp.diff_main("ax\t", "\u0680x\0", false)
    )

    # Overlaps.
    assert_equal(
      [
        Diff.new(:delete, '1'), Diff.new(:equal, 'a'), Diff.new(:delete, 'y'),
        Diff.new(:equal, 'b'), Diff.new(:delete, '2'), Diff.new(:insert, 'xab')
      ],
      @dmp.diff_main('1ayb2', 'abxab', false)
    )

    assert_equal(
      [Diff.new(:insert, 'xaxcx'), Diff.new(:equal, 'abc'), Diff.new(:delete, 'y')],
      @dmp.diff_main('abcy', 'xaxcxabc', false)
    )

    assert_equal(
      [
        Diff.new(:delete, 'ABCD'), Diff.new(:equal, 'a'), Diff.new(:delete, '='),
        Diff.new(:insert, '-'), Diff.new(:equal, 'bcd'), Diff.new(:delete, '='),
        Diff.new(:insert, '-'), Diff.new(:equal, 'efghijklmnopqrs'),
        Diff.new(:delete, 'EFGHIJKLMNOefg')
      ],
      @dmp.diff_main(
        'ABCDa=bcd=efghijklmnopqrsEFGHIJKLMNOefg',
        'a-bcd-efghijklmnopqrs',
        false
      )
    )

    # Large equality.
    assert_equal(
      [
        Diff.new(:insert, ' '), Diff.new(:equal, 'a'), Diff.new(:insert, 'nd'),
        Diff.new(:equal, ' [[Pennsylvania]]'), Diff.new(:delete, ' and [[New')
      ],
      @dmp.diff_main(
        'a [[Pennsylvania]] and [[New', ' and [[Pennsylvania]]', false
      )
    )

    # Timeout.
    @dmp.diff_timeout = 0.1  # 100ms
    a = "`Twas brillig, and the slithy toves\nDid gyre and gimble in the wabe:\nAll mimsy were the borogoves,\nAnd the mome raths outgrabe.\n"
    b = "I am the very model of a modern major general,\nI\'ve information vegetable, animal, and mineral,\nI know the kings of England, and I quote the fights historical,\nFrom Marathon to Waterloo, in order categorical.\n"
    # Increase the text lengths by 1024 times to ensure a timeout.
    a = a * 1024
    b = b * 1024
    start_time = Time.now
    @dmp.diff_main(a, b)
    end_time = Time.now
    # Test that we took at least the timeout period.
    assert(@dmp.diff_timeout <= end_time - start_time, "not timed out")
    # Test that we didn't take forever (be forgiving).
    # Theoretically this test could fail very occasionally if the
    # OS task swaps or locks up for a second at the wrong moment.
    assert(@dmp.diff_timeout * 1000 * 2 > end_time - start_time, "took too long")
    @dmp.diff_timeout = 0

    # Test the linemode speedup.
    # Must be long to pass the 100 char cutoff.
    # Simple line-mode.
    a = "1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n"
    b = "abcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\n"
    assert_equal(@dmp.diff_main(a, b, false), @dmp.diff_main(a, b, true))

    # Single line-mode.
    a = '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'
    b = 'abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij'
    assert_equal(@dmp.diff_main(a, b, false), @dmp.diff_main(a, b, true))

    # Overlap line-mode.
    a = "1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n"
    b = "abcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n"

    diffs_linemode = @dmp.diff_main(a, b, true)
    diffs_textmode = @dmp.diff_main(a, b, false)
    assert_equal(@dmp.diff_text1(diffs_linemode), @dmp.diff_text1(diffs_textmode))
    assert_equal(@dmp.diff_text2(diffs_linemode), @dmp.diff_text2(diffs_textmode))

    # Test null inputs.
    assert_raise ArgumentError do
      @dmp.diff_main(nil, nil)
    end
  end

  # Match tests

  def test_match_alphabet
    # Initialise the bitmasks for Bitap.
    # Unique.
    assert_equal({'a'=>4, 'b'=>2, 'c'=>1}, @dmp.match_alphabet('abc'))

    # Duplicates.
    assert_equal({'a'=>37, 'b'=>18, 'c'=>8}, @dmp.match_alphabet('abcaba'))
  end

  def test_match_bitap
    # Bitap algorithm.
    @dmp.match_distance = 100
    @dmp.match_threshold = 0.5
    # Exact matches.
    assert_equal(5, @dmp.match_bitap('abcdefghijk', 'fgh', 5))

    assert_equal(5, @dmp.match_bitap('abcdefghijk', 'fgh', 0))

    # Fuzzy matches.
    assert_equal(4, @dmp.match_bitap('abcdefghijk', 'efxhi', 0))

    assert_equal(2, @dmp.match_bitap('abcdefghijk', 'cdefxyhijk', 5))

    assert_equal(nil, @dmp.match_bitap('abcdefghijk', 'bxy', 1))

    # Overflow.
    assert_equal(2, @dmp.match_bitap('123456789xx0', '3456789x0', 2))

    # Threshold test.
    @dmp.match_threshold = 0.4
    assert_equal(4, @dmp.match_bitap('abcdefghijk', 'efxyhi', 1))

    @dmp.match_threshold = 0.3
    assert_equal(nil, @dmp.match_bitap('abcdefghijk', 'efxyhi', 1))

    @dmp.match_threshold = 0.0
    assert_equal(1, @dmp.match_bitap('abcdefghijk', 'bcdef', 1))
    @dmp.match_threshold = 0.5

    # Multiple select.
    assert_equal(0, @dmp.match_bitap('abcdexyzabcde', 'abccde', 3))

    assert_equal(8, @dmp.match_bitap('abcdexyzabcde', 'abccde', 5))

    # Distance test.
    @dmp.match_distance = 10  # Strict location.
    assert_equal(nil, @dmp.match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdefg', 24))

    assert_equal(0, @dmp.match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdxxefg', 1))

    @dmp.match_distance = 1000  # Loose location.
    assert_equal(0, @dmp.match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdefg', 24))
  end

  def test_match_main
    # Full match.
    # Shortcut matches.
    assert_equal(0, @dmp.match_main('abcdef', 'abcdef', 1000))

    assert_equal(nil, @dmp.match_main('', 'abcdef', 1))

    assert_equal(3, @dmp.match_main('abcdef', '', 3))

    assert_equal(3, @dmp.match_main('abcdef', 'de', 3))

    # Beyond end match.
    assert_equal(3, @dmp.match_main("abcdef", "defy", 4))

    # Oversized pattern.
    assert_equal(0, @dmp.match_main("abcdef", "abcdefy", 0))

    # Complex match.
    assert_equal(4, @dmp.match_main('I am the very model of a modern major general.', ' that berry ', 5))

    # Test null inputs.
    assert_raise ArgumentError do
      @dmp.match_main(nil, nil, 0)
    end
  end

  # Patch tests

  def test_patch_obj
    # Patch Object.
    p = Patch.new
    p.start1 = 20
    p.start2 = 21
    p.length1 = 18
    p.length2 = 17
    p.diffs = [
      Diff.new(:equal, 'jump'),
      Diff.new(:delete, 's'),
      Diff.new(:insert, 'ed'),
      Diff.new(:equal, ' over '),
      Diff.new(:delete, 'the'),
      Diff.new(:insert, 'a'),
      Diff.new(:equal, "\nlaz")
    ]
    strp = p.to_s
    assert_equal(
      "@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n",
      strp
    )
  end

  def test_patch_fromText
    assert_equal([], @dmp.patch_fromText(""))

    [
      "@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n",
      "@@ -1 +1 @@\n-a\n+b\n",
      "@@ -1 +1 @@\n-a\n+b\n",
      "@@ -0,0 +1,3 @@\n+abc\n"
    ].each do |strp|
      assert_equal(strp, @dmp.patch_fromText(strp).first.to_s)
    end

    # Generates error.
    assert_raise ArgumentError do
      @dmp.patch_fromText('Bad\nPatch\n')
    end
  end

  def test_patch_toText
    [
      "@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n",
      "@@ -1,9 +1,9 @@\n-f\n+F\n oo+fooba\n@@ -7,9 +7,9 @@\n obar\n-,\n+.\n  tes\n"
    ].each do |strp|
      p = @dmp.patch_fromText(strp)
      assert_equal(strp, @dmp.patch_toText(p))
    end
  end

  def test_patch_addContext
    @dmp.patch_margin = 4
    p = @dmp.patch_fromText("@@ -21,4 +21,10 @@\n-jump\n+somersault\n").first
    @dmp.patch_addContext(p, 'The quick brown fox jumps over the lazy dog.')
    assert_equal(
      "@@ -17,12 +17,18 @@\n fox \n-jump\n+somersault\n s ov\n",
      p.to_s
    )

    # Same, but not enough trailing context.
    p = @dmp.patch_fromText("@@ -21,4 +21,10 @@\n-jump\n+somersault\n").first
    @dmp.patch_addContext(p, 'The quick brown fox jumps.')
    assert_equal(
      "@@ -17,10 +17,16 @@\n fox \n-jump\n+somersault\n s.\n",
      p.to_s
    )

    # Same, but not enough leading context.
    p = @dmp.patch_fromText("@@ -3 +3,2 @@\n-e\n+at\n").first
    @dmp.patch_addContext(p, 'The quick brown fox jumps.')
    assert_equal(
      "@@ -1,7 +1,8 @@\n Th\n-e\n+at\n  qui\n",
      p.to_s
    )

    # Same, but with ambiguity.
    p = @dmp.patch_fromText("@@ -3 +3,2 @@\n-e\n+at\n").first
    @dmp.patch_addContext(p, 'The quick brown fox jumps.  The quick brown fox crashes.');
    assert_equal(
      "@@ -1,27 +1,28 @@\n Th\n-e\n+at\n  quick brown fox jumps. \n",
      p.to_s
    )
  end

  def test_patch_make
    # Null case.
    patches = @dmp.patch_make('', '')
    assert_equal('', @dmp.patch_toText(patches))

    text1 = 'The quick brown fox jumps over the lazy dog.'
    text2 = 'That quick brown fox jumped over a lazy dog.'
    # Text2+Text1 inputs.
    expectedPatch = "@@ -1,8 +1,7 @@\n Th\n-at\n+e\n  qui\n@@ -21,17 +21,18 @@\n jump\n-ed\n+s\n  over \n-a\n+the\n  laz\n"
    # The second patch must be "-21,17 +21,18", not "-22,17 +21,18" due to rolling context
    patches = @dmp.patch_make(text2, text1)
    assert_equal(expectedPatch, @dmp.patch_toText(patches))

    # Text1+Text2 inputs.
    expectedPatch = "@@ -1,11 +1,12 @@\n Th\n-e\n+at\n  quick b\n@@ -22,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n"
    patches = @dmp.patch_make(text1, text2)
    assert_equal(expectedPatch, @dmp.patch_toText(patches))

    # Diff input.
    diffs = @dmp.diff_main(text1, text2, false)
    patches = @dmp.patch_make(diffs)
    assert_equal(expectedPatch, @dmp.patch_toText(patches))

    # Text1+Diff inputs.
    patches = @dmp.patch_make(text1, diffs)
    assert_equal(expectedPatch, @dmp.patch_toText(patches))

    # Text1+Text2+Diff inputs (deprecated)
    patches = @dmp.patch_make(text1, text2, diffs)
    assert_equal(expectedPatch, @dmp.patch_toText(patches))

    # Character encoding.
    patches = @dmp.patch_make('`1234567890-=[]\\;\',./', '~!@#$%^&*()_+{}|:"<>?')
    assert_equal("@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;\',./\n+~!@\#$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n", @dmp.patch_toText(patches))

    # Character decoding.
    diffs = [
      Diff.new(:delete, '`1234567890-=[]\\;\',./'),
      Diff.new(:insert, '~!@#$%^&*()_+{}|:"<>?')
    ]
    assert_equal(
      diffs,
      @dmp.patch_fromText(
        "@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;\',./\n+~!@\#$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n"
      ).first.diffs
    )

    # Long string with repeats.
    text1 = 'abcdef' * 100
    text2 = text1 + '123'
    expectedPatch = "@@ -573,28 +573,31 @@\n cdefabcdefabcdefabcdefabcdef\n+123\n"
    patches = @dmp.patch_make(text1, text2)
    assert_equal(expectedPatch, @dmp.patch_toText(patches))

    # Test null inputs.
    assert_raise ArgumentError do
      @dmp.patch_make(nil)
    end
  end

  def test_patch_splitMax
    # Assumes that dmp.Match_MaxBits is 32.
    patches = @dmp.patch_make('abcdefghijklmnopqrstuvwxyz01234567890', 'XabXcdXefXghXijXklXmnXopXqrXstXuvXwxXyzX01X23X45X67X89X0')
    @dmp.patch_splitMax(patches)
    assert_equal("@@ -1,32 +1,46 @@\n+X\n ab\n+X\n cd\n+X\n ef\n+X\n gh\n+X\n ij\n+X\n kl\n+X\n mn\n+X\n op\n+X\n qr\n+X\n st\n+X\n uv\n+X\n wx\n+X\n yz\n+X\n 012345\n@@ -25,13 +39,18 @@\n zX01\n+X\n 23\n+X\n 45\n+X\n 67\n+X\n 89\n+X\n 0\n", @dmp.patch_toText(patches))

    patches = @dmp.patch_make('abcdef1234567890123456789012345678901234567890123456789012345678901234567890uvwxyz', 'abcdefuvwxyz')
    oldToText = @dmp.patch_toText(patches)
    @dmp.patch_splitMax(patches)
    assert_equal(oldToText, @dmp.patch_toText(patches))

    patches = @dmp.patch_make('1234567890123456789012345678901234567890123456789012345678901234567890', 'abc')
    @dmp.patch_splitMax(patches)
    assert_equal("@@ -1,32 +1,4 @@\n-1234567890123456789012345678\n 9012\n@@ -29,32 +1,4 @@\n-9012345678901234567890123456\n 7890\n@@ -57,14 +1,3 @@\n-78901234567890\n+abc\n", @dmp.patch_toText(patches))

    patches = @dmp.patch_make('abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1', 'abcdefghij , h : 1 , t : 1 abcdefghij , h : 1 , t : 1 abcdefghij , h : 0 , t : 1')
    @dmp.patch_splitMax(patches)
    assert_equal("@@ -2,32 +2,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n@@ -29,32 +29,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n", @dmp.patch_toText(patches))
  end

  def test_patch_addPadding
    # Both edges full.
    patches = @dmp.patch_make('', 'test')
    assert_equal("@@ -0,0 +1,4 @@\n+test\n", @dmp.patch_toText(patches))
    @dmp.patch_addPadding(patches)
    assert_equal("@@ -1,8 +1,12 @@\n %01%02%03%04\n+test\n %01%02%03%04\n", @dmp.patch_toText(patches))

    # Both edges partial.
    patches = @dmp.patch_make('XY', 'XtestY')
    assert_equal("@@ -1,2 +1,6 @@\n X\n+test\n Y\n", @dmp.patch_toText(patches))
    @dmp.patch_addPadding(patches)
    assert_equal("@@ -2,8 +2,12 @@\n %02%03%04X\n+test\n Y%01%02%03\n", @dmp.patch_toText(patches))

    # Both edges none.
    patches = @dmp.patch_make('XXXXYYYY', 'XXXXtestYYYY')
    assert_equal("@@ -1,8 +1,12 @@\n XXXX\n+test\n YYYY\n", @dmp.patch_toText(patches))
    @dmp.patch_addPadding(patches)
    assert_equal("@@ -5,8 +5,12 @@\n XXXX\n+test\n YYYY\n", @dmp.patch_toText(patches))
  end

  def test_patch_apply
    @dmp.match_distance = 1000
    @dmp.match_threshold = 0.5
    @dmp.patch_deleteThreshold = 0.5
    # Null case.
    patches = @dmp.patch_make('', '')
    results = @dmp.patch_apply(patches, 'Hello world.')
    assert_equal(['Hello world.', []], results)

    # Exact match.
    patches = @dmp.patch_make('The quick brown fox jumps over the lazy dog.', 'That quick brown fox jumped over a lazy dog.')
    results = @dmp.patch_apply(patches, 'The quick brown fox jumps over the lazy dog.')
    assert_equal(['That quick brown fox jumped over a lazy dog.', [true, true]], results)

    # Partial match.
    results = @dmp.patch_apply(patches, 'The quick red rabbit jumps over the tired tiger.')
    assert_equal(['That quick red rabbit jumped over a tired tiger.', [true, true]], results)

    # Failed match.
    results = @dmp.patch_apply(patches, 'I am the very model of a modern major general.')
    assert_equal(['I am the very model of a modern major general.', [false, false]], results)

    # Big delete, small change.
    patches = @dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy')
    results = @dmp.patch_apply(patches, 'x123456789012345678901234567890-----++++++++++-----123456789012345678901234567890y')
    assert_equal(['xabcy', [true, true]], results)

    # Big delete, big change 1.
    patches = @dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy')
    results = @dmp.patch_apply(patches, 'x12345678901234567890---------------++++++++++---------------12345678901234567890y')
    assert_equal(['xabc12345678901234567890---------------++++++++++---------------12345678901234567890y', [false, true]], results)

    # Big delete, big change 2.
    @dmp.patch_deleteThreshold = 0.6
    patches = @dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy')
    results = @dmp.patch_apply(patches, 'x12345678901234567890---------------++++++++++---------------12345678901234567890y')
    assert_equal(['xabcy', [true, true]], results)
    @dmp.patch_deleteThreshold = 0.5

    # Compensate for failed patch.
    @dmp.match_threshold = 0.0
    @dmp.match_distance = 0
    patches = @dmp.patch_make('abcdefghijklmnopqrstuvwxyz--------------------1234567890', 'abcXXXXXXXXXXdefghijklmnopqrstuvwxyz--------------------1234567YYYYYYYYYY890')
    results = @dmp.patch_apply(patches, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567890')
    assert_equal(['ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567YYYYYYYYYY890', [false, true]], results)
    @dmp.match_threshold = 0.5
    @dmp.match_distance = 1000

    # No side effects.
    patches = @dmp.patch_make('', 'test')
    patchstr = @dmp.patch_toText(patches)
    @dmp.patch_apply(patches, '')
    assert_equal(patchstr, @dmp.patch_toText(patches))

    # No side effects with major delete.
    patches = @dmp.patch_make('The quick brown fox jumps over the lazy dog.', 'Woof')
    patchstr = @dmp.patch_toText(patches)
    @dmp.patch_apply(patches, 'The quick brown fox jumps over the lazy dog.')
    assert_equal(patchstr, @dmp.patch_toText(patches))

    # Edge exact match.
    patches = @dmp.patch_make('', 'test')
    results = @dmp.patch_apply(patches, '')
    assert_equal(['test', [true]], results)

    # Near edge exact match.
    patches = @dmp.patch_make('XY', 'XtestY')
    results = @dmp.patch_apply(patches, 'XY')
    assert_equal(['XtestY', [true]], results)

    # Edge partial match.
    patches = @dmp.patch_make('y', 'y123')
    results = @dmp.patch_apply(patches, 'x')
    assert_equal(['x123', [true]], results)
  end

end
