#!/usr/bin/perl
# brick.pl ver 0.5 20070622 can draw a piece now given X,Y
	# now need to push $piece{y}{x} into $solution{$move};
# brick.pl ver 0.4 20070621 need to draw the tree of the moves
		#		I think Move $move_number Piece:puzzle
# brick.pl ver 0.3 20070620 fixed block_is_in_pieces 
# brick.pl ver 0.2 20070620 find works and pieces are being found
#			need to fix block_is_in_pieces
# brick.pl ver 0.1 20070601 alexx at alexx dot net
use strict "vars";
#use strict "refs";
use strict "subs";

my %puzzle1= (
9       => [ "W","W","W","W","P","W","W","W","W","W"],
8       => [ "W","W","G","T","T","W","G","V","W","W"],
7       => [ "W","W","T","G","T","W","P","V","W","W"],
6       => [ "W","W","G","V","G","W","G","G","G","W"],
5       => [ "P","W","T","V","G","R","G","R","V","T"],
4       => [ "P","R","T","R","P","P","P","V","T","R"],
3       => [ "P","V","V","V","R","V","V","V","T","R"],
2       => [ "T","V","P","R","P","R","V","G","G","R"],
1       => [ "T","T","P","P","P","R","G","R","G","V"],
);


$|=1;
my %puzzle= (
4 => [ "W", "W", "W", "W", "T", "W"],
3 => [ "W", "W", "W", "W", "T", "W"],
2 => [ "V", "W", "V", "W", "V", "V"],
1 => [ "V", "V", "T", "T", "V", "V"],
);

if($ARGV[0] eq '-1'){ %puzzle = %puzzle1; }

# the min block size that can be removed
my $mbs = 3;
# score per block
# can be determined by the size of the block
# and then linier or exponential
# Scoring Rate
my $sr = 'l'; # l=linier e=exponetial s=squared f=fixed
# for non fixed number of points for $mbs
my $mbsp = 0;
my $null = 'W';
# linier = X points for the first clickable and then X+1 for X+1 blocks
# exponetial = X points for the first and then X*X for the next
# squared = X^2 points for each clickable block
# fixed = refer to %spb hash
my %spb = (
1 => 0,
);
my $plm = 0; # pointless move - move EVERYTHING to the left in the remove step
my $dimentions = 0; # 0 = flat 1 = wrapped left to right 2 = wrapped top to bottom 3 = 1+2 hehehe

my $verb = 0;
my $debug = 0;
my $show = 0;
if($ARGV[0] eq '-d'){ $debug = 1; $verb =1; }
if($ARGV[0] eq '-v'){ $verb =1; }
if($ARGV[0] eq '-s'){ $show =1; }

# gravity may be stronger or weaker than the wind
# (gravity pulls down and the wind moves things sideways)
my $gowf = 'g'; #gravity or wind first

# should probably write the solution file to disk so this can be run
# on more than one machine or stopped and started
# and the rows can be reversed (or even shuffled)
# to spread this over more machines.
  my %solution;

sub print_piece_hash
{
  my $piece = shift;
#  my  $colour = $piece->{colour};
#  delete($piece->{colour});
  my $next_block = keys %{$piece};
 # print "Print Piece Hash: In this piece we have $next_block blocks\n";

	print "\%piece = (\n";
	foreach my $block (sort {$a <=> $b} keys %{$piece})
	{
		print "\t$block => {\n";
		foreach my $loc ( keys %{ $piece->{$block} })
		{
			print "\t\t$loc => $piece->{$block}{$loc}\n";
		}
		print "\t},\n";
	}
	print ");\n";
#  $piece->{colour} = $colour;
}

sub check_solved
{
	#here we are looking for a puzzle with no pieces
        my $puzzle = shift;
        foreach my $row (keys %{$puzzle})
        {
                foreach my $block ( @{ $puzzle->{$row} } )
                {
                        return(0) if($block ne 'W');
                }
        }
	print "This puzzle is solved!\n";
	return(1);
}

sub print_solution
{
	
}

sub print_puzzle
{
	my $puzzle = shift;
	my $dp = '';
	if( (keys %{$puzzle} ) >= 10)
	{
		$dp = ' ';
	}
        foreach my $row (sort {$b <=> $a} keys %{$puzzle})
        {
		print "$dp$row: ";
        	foreach my $block ( @{ $puzzle->{$row} } )
		{
			print "$block,";
		}
		print "\n";
        }
	print "$dp   ";
	for(my $i=0;$i<@{$puzzle->{1}};$i++)
	{
		print "$i|";
	}
	print "\n";
}

sub print_piece
{
        my $piece = shift;
        my $puzzle = shift;
	my $piece_x = $piece->{1}{x};
	my $piece_y = $piece->{1}{y};
	my $block_colour = $puzzle->{$piece_y}[$piece_x];
	print "Block Col = $block_colour\n";
        my $dp ='';
        if( (keys %{$puzzle}) >= 10){$dp = ' ';}
        foreach my $row (sort {$b <=> $a} keys %{$puzzle})
        {
                print "$dp$row: ";
                #foreach my $block ( @{ $puzzle->{$row} } )
                for (my $col=0;$col<@{$puzzle->{1}};$col++)
                {
			#if this block is part of $piece
			#then print it
			if(check_block_is_in_piece($piece,$col,$row) != 0)
                        {
				print "$puzzle->{$row}[$col],";
			}else{
				print " ,";
			}
                }
                print "\n";
        }
        print "$dp   ";
        for(my $i=0;$i<@{$puzzle->{1}};$i++)
        {
                print "$i|";
        }
        print "\n";
}


sub check_block_is_in_piece
{
	my $piece = shift;
	my $loc_x = shift;
	my $loc_y = shift;
	foreach my $block (keys %{$piece})
        {
		if($piece->{$block}{x} ==  $loc_x &&
		   $piece->{$block}{y} ==  $loc_y )
		{
			return("$block");
		}
		else
		{
			print "$piece->{$block}{x} != $loc_x && $piece->{$block}{y} != $loc_y\n" if $verb==1;
		}
        }
	return(0);
}

sub block_is_in_pieces
{
   my $pieces = shift;
   my $loc_x = shift;
   my $loc_y = shift;
   print "Checking $loc_x,$loc_y is not in the pieces\n" if $verb==1;
   foreach my $piece ( keys %{$pieces})
   {
	print "BIIP: is $loc_x,$loc_y in $piece:\n" if $verb==1; 
	print_piece_hash($pieces->{$piece}) if $verb==1;
        foreach my $block (keys %{$pieces->{$piece}})
        {
                if($pieces->{$piece}{$block}{x} ==  $loc_x &&
                   $pieces->{$piece}{$block}{y} ==  $loc_y )
                {
			print "$piece->{$block}{x} == $loc_x && $piece->{$block}{y} == $loc_y\n" if $verb==1;
                        return("$block");
                }
        }
   }
   return(0);
}

sub print_pieces
{
   my $pieces = shift;
 print "\%pieces = (\n";
   foreach my $piece (sort {$a <=> $b} keys %{$pieces})
   {
     print "\t \$piece $piece = (\n";
    
        #foreach my $block (sort {$a <=> $b} keys %{$piece})
        #foreach my $block (sort {$a <=> $b} keys %{$piece->{$piece}})
        foreach my $block (sort {$a <=> $b} keys %{$pieces->{$piece}})
        {
                print "\t\tBlock $block => {\n";
                foreach my $loc ( keys %{ $pieces->{$piece}{$block} })
                #foreach my $loc ( keys %{ $block })
                #foreach my $loc ( keys %{ $piece{$block} })
                {
                        print "\t\t\t$loc => $pieces->{$piece}{$block}{$loc}\n";
			
                }
                print "\t\t},\n";
        }
   print "\t);\n";
   }
   print ");\n";
}



sub findpiece
{
 #this finds a piece given a matrix location
 # which is pushed into the piece hash as the first block
  #my %to_check; # hash of the blocks that have been added but not checked
  my $puzzle = shift;
  my $piece = shift;
 print_piece_hash($piece) if $verb==1;
  #my $colour = $piece->{colour};
  #delete($piece->{colour});
  my $blocks = keys %{$piece};

  #my $test = check_block_is_in_piece($piece,5,3);
  #if($test > 0){ print "5,3 is already block $test in the piece\n";}
  #else{ print "5,3 is not already in the piece :$test:\n";}

  my $block_x = $piece->{$blocks}{x};
  my $block_y = $piece->{$blocks}{y};
  my $block_colour = $puzzle->{$block_y}[$block_x];

  if($block_colour eq 'W'){ return(); }
  print "Find Piece: The block colour = $block_colour $block_x $block_y\n" if $verb==1;
  #add this block to the piece
  print "Need to check that $block_x,$block_y is not already in the piece hash\n" if $verb==1;
  if(check_block_is_in_piece($piece,$block_x,$block_y) <= 0 )
  {
	  print "This is the start of a new block at $block_x,$block_y colour $block_colour\n" if $verb==1;
	  $piece->{$blocks}{x} = $block_x;
	  $piece->{$blocks}{y} = $block_y;
	  print_piece_hash($piece) if $verb==1;
  }else{
	print "block at $block_x,$block_y colour $block_colour is already in in this piece\n" if $verb==1;
  }


  print_puzzle($puzzle) if $verb==1;
  my $above_x = $block_x;
  my $above_y = $block_y+1;
  my $above;
  #my $rows = keys %{$puzzle};
  #my $cols = @{$puzzle{1}};

  if($above_y <= (keys %{$puzzle}))
  {
	$above = $puzzle->{$above_y}[$above_x];
  }
  # need to check that we have not gone off the top
  if($dimentions >= 2 && ($above_y > ( keys %{$puzzle} ) )){ $above_y = 1; }
  
  if($above && $above ne 'W') # no point in looking if the next piece is off the puzzle or is a blank
  {
  	if($above eq $block_colour)
  	{
		#check we don't already have this block in the piece
		if( check_block_is_in_piece($piece,$above_x,$above_y) == 0 )
		{
 			print_piece_hash($piece) if $verb==1;
			
			#add above to the piece
			my $next_block = keys %{$piece};
			$next_block++;
			print "going to add this block to the piece: it will be block $next_block and is above the last block\n" if $verb==1;
	  		$piece->{$next_block}{x} = $above_x;
	  		$piece->{$next_block}{y} = $above_y;
			print "Adding blockA $next_block $above_x,$above_y $above to the piece\n" if $verb==1;
			findpiece($puzzle,$piece);
		}
		
	  }
  }

  my $below_x = $block_x;
  my $below_y = $block_y-1;
  my $below;
  if($below_y >= 1)
  {
	$below = $puzzle->{$below_y}[$below_x];
  }

  if($below eq $block_colour)
  {
	print "BELOW: The Block at Col $below_x and Row $below_y is color $below and piece is $block_colour\n" if $verb==1;
        #check we don't already have this block in the piece
        if( check_block_is_in_piece($piece,$below_x,$below_y) == 0 )
        {
                #add this to the piece
                my $next_block = keys %{$piece};
		$next_block++;
		print "going to add this block to the piece: it will be block $next_block and is below the last block\n" if $verb==1;
                $piece->{$next_block}{x} = $below_x;
                $piece->{$next_block}{y} = $below_y;
		print "Adding blockB $next_block $below_x,$below_y $below to the piece\n" if $verb==1;
		findpiece($puzzle,$piece);
        }
	else
	{
		print "This piece below is already in the piece\n" if $verb==1;
	}
  }

  my $left_x = $block_x-1;
  my $left_y = $block_y;
  my $left;
  if($left_x >= 0)
  { 
	$left = $puzzle->{$left_y}[$left_x];
  }

  if($left eq $block_colour)
  {
	print "The block to the Left is $left and the piece colour is $block_colour\n" if $verb==1;
        #check we don't already have this block in the piece
        if( check_block_is_in_piece($piece,$left_x,$left_y) == 0 )
        {
                #add this to the piece
                my $next_block = keys %{$piece};
                $next_block++;
                $piece->{$next_block}{x} = $left_x;
                $piece->{$next_block}{y} = $left_y;
                print "Adding blockL $next_block $left_x,$left_y $left to the piece\n" if $verb==1;
		findpiece($puzzle,$piece);
        }
  }

  my $right_x = $block_x+1;
  my $right_y = $block_y;
  my $right;
  if($right_x <= @{$puzzle{1}})
  {
	$right = $puzzle->{$right_y}[$right_x];
  }

  if($right eq $block_colour)
  {
        #check we don't already have this block in the piece
        if( check_block_is_in_piece($piece,$right_x,$right_y) == 0 )
        {
                #add this to the piece
                my $next_block = keys %{$piece};
                $next_block++;
                $piece->{$next_block}{x} = $right_x;
                $piece->{$next_block}{y} = $right_y;
                print "Adding blockR $next_block $right_x,$right_y $right to the piece\n" if $verb==1;
		findpiece($puzzle,$piece);
        }
  }

 # if($block_colour = $puzzle->{$block_x}[$block_y];
 # my $rows = keys %puzzle;
 # my $cols = @{$puzzle{1}};

}

sub find_clickable
{
 #this finds all clickable pieces
 my %unclickable; #a hash of found pieces that are not clickable;
 my $puzzle = shift;
 my $pieces = shift; #empty hash that will hold the pieces that are clickable
 print_puzzle($puzzle) if ($verb==1||$show==1);

	ROW: foreach my $row (sort {$b <=> $a} keys %{$puzzle})
        {
	#	my $xloc = 0;
               # COL: foreach my $block ( @{ $puzzle->{$row} } )
                COL: for(my $j=0;$j<@{$puzzle->{$row}};$j++)
                {
			#check this block is not NULL
			#next COL if $block eq 'W';
			next COL if $puzzle->{$row}[$j] eq 'W';

			#check this block is not already in a piece
			print "Checking $j,$row is not in %pieces\n" if $show==1;
			next COL if block_is_in_pieces($pieces,$j,$row);
			next COL if block_is_in_pieces(\%unclickable,$j,$row);
			print "Checking $j,$row is not in UNCLICKABLE\n" if $show==1;
			#if(block_is_in_pieces(\%unclickable,$j,$row))
			#{
#
	#			print "$j,$row is already in UNCLICKABLE" if $verb==1;
	#			my $alreadypiece = block_is_in_pieces(\%unclickable,$j,$row);
		#		print_piece_hash(\%{ $unclickable{$alreadypiece} }) if $verb==1;
			#	next COL;
			#}#
			#else
			#{
			#	print "$j,$row is NOT in UNCLICKABLE\n" if $verb==1;
			#	for(my $m=1;$m<=(keys %unclickable);$m++)	
			#	{
			#		print "printing $m piece in UNCLICKABLE\n" if $verb==1;
			#		print_piece_hash(\%{ $unclickable{$m} }) if $verb==1;
			#	}
			#}
			my %piece = ( '1' => { 'x' => $j, 'y' => $row, } );
			findpiece($puzzle,\%piece);
			if( (keys %piece) >= $mbs) #this piece is big enough to click
			{
				my $next_piece =  keys %{$pieces};
				$next_piece++;
				for my $block (keys %piece)
				{
					for my $loc (keys %{ $piece{$block} })
					{
						$pieces->{$next_piece}{$block}{$loc} = "$piece{$block}{$loc}";
					}
				}
				print_pieces($pieces) if $verb==1;
			}else{
				my $next_piece =  keys %unclickable;
				$next_piece++;
				#$unclickable{$next_piece} = %piece;
				for my $block (keys %piece)
				{
					for my $loc (keys %{ $piece{$block} })
					{
						$unclickable{$next_piece}{$block}{$loc} = "$piece{$block}{$loc}";
					}
				}
				
			}
                }
        }
 print "We have been through the puzzle and found " . (keys %{$pieces}) . " CLickAble Pieces\n" if $show==1;
}

sub remove
{
  #this removes a piece from the puzzle
   my $puzzle = shift;
   my $piece = shift;
   my $score = keys %{$piece};
   if($sr eq 'l')
   {
	$score = $mbsp + ( ( $score - $mbs ) );
   }
   #add other scoring types

  # remove each block of the piece from the puzzle

  for my $block (keys %{ $piece })
  {
	my $x = $piece->{$block}{x};
	my $y = $piece->{$block}{y};
	print "Removing block $x,$y from the puzzle\n" if $show==1;
	print_puzzle($puzzle) if $show==1;
	$puzzle{$y}[$x] = 'W';
	print_puzzle($puzzle) if $show==1;
  }
  # now move the pieces down that are left

  if($gowf eq 'g') #gravity first
  {
    #check each row for a !null with a null below it and "swap"
    my $finished_move=0;
    my $clean_pass=0;
    while($finished_move==0)
    {
     ROW: foreach my $row (sort {$a <=> $b} keys %{$puzzle})
      {
	next ROW if $row <= 1;
	#print "Checking row $row for holes\n";
	my $row_below = $row-1;
        #    foreach my $block ( @{ $puzzle->{$row} } )
	for(my $i=0;$i<@{$puzzle->{1}};$i++)
        {
		my $block_below = $puzzle->{$row_below}[$i];
		my $block = $puzzle->{$row}[$i];
                if($block ne 'W' && $block_below eq 'W')
		{
			$clean_pass++;
			$puzzle->{$row}[$i] = $block_below;
			$puzzle->{$row_below}[$i] = $block;
		}
	}
       }
	if($clean_pass >= 1){ $clean_pass = 0; }else{
	$finished_move=1; }
     }
	print "Moved the pieces about\n" if $verb==1;
	print_puzzle($puzzle) if $verb==1;
    #check each col for all nulls and move col+1 to col
    my $done_move=0;
    $clean_pass=0;
	my $cols2chk = @{$puzzle->{1}};
   # we don't HAVE to move any cols unless they are blank in the middle
   my $found_filled_col=0;
   if($plm==1){ $found_filled_col = 1;}
   while($done_move==0)
   {
	print "We have " . $cols2chk . " cols to check\n" if $verb==1;
	#print "We have " . @{$puzzle->{1}} . " cols to check\n";
	COL: for(my $i=0;$i<$cols2chk;$i++)
	#COL: for(my $i=0;$i<@{$puzzle->{1}};$i++)
	{
		my $colsmone = $cols2chk-1;
		next COL if $i == $colsmone;
		next COL if $i == $cols2chk;
		next COL if $i >= $cols2chk;
	   print "Checking if col $i is blank\n" if $verb==1;
		#check that this col is empty
		my $empty_col_found=1;
		my $mt_col_nxt_to_blxs=0;
		my $j=$i+1;
		for(my $k=1;$k<=(keys %{$puzzle});$k++)
		{
		  if($puzzle->{$k}[$i] ne 'W'){ $empty_col_found=0;}
		  if($puzzle->{$k}[$j] ne 'W'){ $mt_col_nxt_to_blxs=1;}
		}
  #NTS you are here
  #You are trying to make this skill moving cols if you don't have to
		if($empty_col_found==1){$found_filled_col=1;}
	#	next COL if $found_filled_col==0 && $empty_col_found==1;
	#	want to just skill the moving if the rest of the colls are
	#	just blank
		if($mt_col_nxt_to_blxs==1 && $empty_col_found==1)
		{
			$clean_pass++;
			MOVE: for(my $k=1;$k<=(keys %{$puzzle});$k++)
			{
			   next MOVE if $puzzle->{$k}[$j] eq 'W';
			  print "moving $j,$k($puzzle->{$k}[$j]) to $i,$k ($puzzle->{$k}[$i]) \n" if $verb==1;
				$puzzle->{$k}[$i] = $puzzle->{$k}[$j];
				$puzzle->{$k}[$j] = 'W';
			}
		}
	}
	if($clean_pass >= 1){ $clean_pass=0;}
	else{ $done_move=1;}
   }

  }
  # and returns the score. The puzzle was just a pointer
  # so that goes back anyway
  return($score);
}

sub solve
{
  my $puzzle = shift;
  my $score = shift;
  my $move = shift;
  my $rows = keys %{$puzzle};
  my $cols = @{$puzzle{1}};
  my $solved=0;
  my $nextmove = $move; $nextmove++;

  while($solved==0)
  # we may want to go on and find the solution with 
  # the highest score so the "check_solved" may have to take that into consideration
  {
        # find clickable blocks
	my %pieces; # a hash of all the clickable pieces
        find_clickable($puzzle,\%pieces);
	print "MOVE $nextmove: " .(keys %pieces). " clickable pieces\n";
	print_puzzle(\%puzzle) if $show==1;
	
        if( (keys %pieces ) == 0){ $solved = 1; } # solved that branch
        # add options to %solution tree

	# NEW we could do that and then print_solution would find the solutions that end with
	# a clear board or the highest score
 	
	$move++;
	#$solution{$move} = @clickable;
        # we can then click each one and update the puzzle
        foreach my $piece_number (sort {$b <=> $a} keys %pieces)
        {
		my %this_piece = %{ $pieces{$piece_number} };
		# make a copy of the puzzle;
		#NTS here
		my %new_puzzle;
		%new_puzzle = %{$puzzle};
		print "MOVE $nextmove - Removing:\n";
		print_piece(\%this_piece,\%new_puzzle);
		print "From:\n";
		print_puzzle(\%new_puzzle);
	#	print "The New puzzle is:\n";
	#	print_puzzle(\%new_puzzle);
                $score .= &remove(\%new_puzzle,\%this_piece);
		print_puzzle(\%new_puzzle) if $verb==1;
		if(check_solved(\%new_puzzle) == 1)
		{
			$solved = 1;
			print_solution();
			exit;
		}
		# I think that we have to pass the move number to the solver so it can 
		# know where to put the moves into the solution tree
                $score = solve(\%new_puzzle,$score,$nextmove);
        }
        # work out if we have solved this puzzle or have run out
        # of paths to walk
  }
  return($score);
}

		#hash,score,moves
my $score = solve(\%puzzle,0,0);

#print_solution(\%solution);

exit(0);


