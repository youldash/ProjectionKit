//
//  PKPolyhedralProjection.m
//  ProjectionKit
//
//  Created by Mustafa Youldash on 30/04/2015.
//  Copyright (c) 2015 Core Innovation. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	* Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//
//	* Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation
//	and/or other materials provided with the distribution.
//
//	* Neither the name of the author nor the names of its contributors may be used
//	to endorse or promote products derived from this software without specific
//	prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
//	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PRPKUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "PKPolyhedralProjection.h"

@implementation PKPolyhedralProjection

#pragma mark -
#pragma mark Creating

/**
 *	The Polyhedral Projection (PP) algorithm.
 *	Returns the N-dimensional projection graph of the input graph.
 *
 *	@param	graph				An edge-weighted, undirected graph; each value in input is an array of values of a single variable for each data point.
 *	@param	start				A starting index.
 *	@param	dimensions			An array of dimensions (column indices).
 *	@param	minimumArea			A "Minimum Area" property flag.
 *	@param	minimumPerimeter	A "Minimum Perimeter" property flag.
 *	@param	mapNNC				A Nearest Neighbor Chain (NNC) mapping sequence flag.
 *	@param	mapEmanatingEdges	An emanating edges mapping sequence flag.
 *  @param	numberOfDimensions	The number of output dimensions.
 *  @param	numberOfIterations	The maximum number of iterations.
 *	@param	projectionType		A projection type (N-dimensional).
 *  @param	completionHandler	A completion handler.
 *  @param	errorHandler		An error handler.
 *
 *	@return	The new algorithm operation.
 */
+ (instancetype)polyhedralProjectionWithGraph:(id<PKGraphDelegate>)graph
									fromIndex:(NSUInteger)start
								   dimensions:(PKIntegerArray *)dimensions
								  minimumArea:(BOOL)minimumArea
							 minimumPerimeter:(BOOL)minimumPerimeter
									   mapNNC:(BOOL)mapNNC
							mapEmanatingEdges:(BOOL)mapEmanatingEdges
						   numberOfDimensions:(NSUInteger)numberOfDimensions
						   numberOfIterations:(NSUInteger)numberOfIterations
							   projectionType:(PKProjectionType)projectionType
							completionHandler:(PKCompletionBlock)completionHandler
								 errorHandler:(PKErrorBlock)errorHandler
{
	// Immutable PP, just return a new reference to itself (retained automatically by ARC).
	PKPolyhedralProjection *polyhedralProjection =
	[super triangularProjectionWithGraph:graph
							   fromIndex:start
							  dimensions:dimensions
							 minimumArea:minimumArea
						minimumPerimeter:minimumPerimeter
					  numberOfIterations:numberOfIterations
						  projectionType:projectionType
					   completionHandler:completionHandler
							errorHandler:errorHandler];
	
	if (polyhedralProjection) {
		
		// Initialization code.
		polyhedralProjection.name = @"Polyhedral Projection";
		polyhedralProjection.numberOfDimensions = numberOfDimensions;
		polyhedralProjection.mapNNC = mapNNC;
		polyhedralProjection.mapEmanatingEdges = mapEmanatingEdges;
	}
	
	// Return this PP operation.
	return polyhedralProjection;
}

#pragma mark -
#pragma mark Operating

/**
 *  Returns a the Nearest Neighbor Chain (NNC) of nodes.
 *
 *  @param visited An array of visited nodes.
 *
 *  @return The chain.
 */
- (id<PKEnumeratorDelegate>)nearestNeighborChainWithVisited:(PKIntegerArray *)visited
{
	return nil;
}
	
#pragma mark -
#pragma mark NSOperation

/**
 *	Invokes the chosen algorithm...
 *
 *	Called when an instance is passed to an NSOperationQueue.
 *
 *  Constructs a 3-dimensional projection graph using the TP3 algorithm.
 */
- (void)main
{
	// Return a log in HTML format, showing results.
	NSMutableString *log = [NSMutableString string];
	
	// Get a reference to the current number of nodes in the passing graph.
	NSUInteger numberOfNodes = self.graph.numberOfNodes;
	
	// Reference index used to track the current node being processed.
	NSUInteger nodeIdx = 0;
	
	// Enforce the output dimensions for all nodes to be N-dimensional.
	// This will effectively represent each node as a N-dimensional vector.
	NSUInteger numberOfDimensions = self.numberOfDimensions;
	
	// Establish the Polyhedral Projection (PP) graph.
	id<PKGraphDelegate> PPGraph = [[PKDigraphAsMatrix alloc] initWithIdentifier:@"PP Digraph" length:numberOfNodes];

	// Establish an array of visited nodes.
	PKIntegerArray *visited = [PKIntegerArray arrayWithLength:numberOfNodes
													baseIndex:0
												 initialValue:NO];
	
	// Establish the results array (for logging).
	PKArray *results = [PKArray arrayWithLength:7];

	// Append the current record to the results array.
	[results replaceObjectAtIndex:0
					   withObject:(self.minimumArea ? @"Minimum Area" :
								   (self.minimumPerimeter ? @"Minimum Perimeter" : @"Minimum Distance"))];

	// Save the time prior operation execution.
	CFAbsoluteTime timeSinceOperation = CFAbsoluteTimeGetCurrent();
	
	// Header.
	[log appendFormat:
	 @"<strong><font color=\"#FFFFFF\">Mapping %lu Points in %lu-Dimensions:</font></strong><br />",
	 numberOfNodes,
	 numberOfDimensions];

	// Unordered list.
//	[log appendString:@"<ul>"];
	
	// Get a reference to the seed node.
	PKNode *P0 = [self.graph nodeAtIndex:self.startIndex];
	
	// Set the output dimensions for this node to be N-dimensional.
	P0.numberOfDimensions = numberOfDimensions;
	
	// The origin of the N-dimensional Cartesian space can be selected arbitrarily.
	// Therefore, set the first point P[0] as located at the origin.
	P0.isOrigin = YES;
	P0.color = self.projection.flipColors ? [PKNode seedColorOverWhite] : [PKNode seedColorOverBlack];

	// Mark this node as visited.
	// By doing so, we effectively set the first recorded distance to be the smallest.
	[visited replaceIntegerAtIndex:P0.number withInteger:YES];
	
	// Set the first recorded distance, assumed, to the smallest (0.0).
	[[self.tableEntry objectAtIndex:P0.number] setDistance:0.0];
	
	// Construct a Minimum Spanning Tree (MST) via assigning table entry references.
	// [self constructMinimumSpanningTreeFromNode:P0];
	
	@try { // Adding the new node to the projection model.
		
		// Does not throw an exception at this stage.
		[PPGraph insertNode:P0 projection:self.projection];
	}
	@catch (NSException *exception) {
		
		// Handle the error/exception.
		[self handleException:exception];
	}
	@finally {
		
		// Update the log.
//		[log appendFormat:@"<li>Set the first point <strong>P[%lu]</strong> as located at the origin,<br />"
//		 "<font color=#AAFFAA><strong>%@</strong></font>", nodeIdx, P0];
		
		// Increment the index counter.
		++nodeIdx;
	}
	
	/**
	 *	Next, we find the nearest neighbor to the seed node.
	 *	Set it as the nearest node to origin, and map its direction towards the positive region of the X axis.
	 *
	 *  The direction of the x-axis of the 3-dimensional cartesian space can be selected arbitrarily.
	 *	Therefore, set the line from point P[0] to point P[1].
	 *	That is, from P1 to P2 as the x-axis direction, to maintain distance scales.
	 */
	PKNode *P1 = [self nearestNeighborWithPreVisitor:NULL
										 postVisitor:NULL
												node:P0
											 visited:visited];
	
	// Origin is already determined.
	P1.isOrigin = NO;

	// Set the output dimensions for this node to be 3-dimensional.
	P1.numberOfDimensions = numberOfDimensions;
	
	// distance(P0, P1);
	double P0P1 = [self.graph edgeFromIndex:P0.number toIndex:P1.number].weight.doubleValue;
	
	// Set it as the nearest node to origin, and map its direction towards the positive region of the "x" axis.
	// This effectively sets P1 as due East of P0,
	// which may not be geographically correct if we are dealing with localities on the surface of the Earth.
	[P1.positions replaceObjectAtIndex:0 withObject:@(P0P1)];
	[P1 updatePosition];
	
	@try { // Adding the new node to the projection model.
		
		// Does not throw an exception at this stage.
		[PPGraph insertNode:P1 projection:self.projection];
	}
	@catch (NSException *exception) {
		
		// Handle the error/exception.
		[self handleException:exception];
	}
	@finally {
		
		// Update the log.
//		[log appendFormat:@"<li>Set the line from point <strong>P[%lu]</strong> to point <strong>P[%lu]</strong>,<br />i.e. "
//		 "from <font color=#FFFF00><strong>%@</strong></font> to <font color=#FFFF00><strong>%@</strong></font> "
//		 "as the x-axis direction,<br />"
//		 "<font color=#AAFFAA><strong>%@</strong></font>", P0.number, P1.number, P0.identifier, P1.identifier, P1];
		
		// Increment the index counter.
		++nodeIdx;
	}
	
	/**
	 *	Now consider N-dimensional coordinates for the point P2.
	 *	Points P0, P1 and P2 form a triangle whose sides are known.
	 *	We need to determine the angle α at P0 in order to get the coordinates (x, y) of P2.
	 *	In the process of making the coordinates of P2, we introduce the coordinate Q such that P1P2 and QP2 are perpendicular lines.
	 *	This means that QP2 is pointing in the y-axis direction.
	 *	This effectively sets P3 as to the North of P0 and P1 which may not be geographically correct if we are dealing with localities on the surface of the Earth.
	 *	However the choice yet remains, since we are allowed to turn the map upside-down if desired.
	 *
	 *	In other words, we set that point in the "positive" y-domain
	 *	(if it meets any of these criteria, the point should be placed on the P0P1 axis).
	 */
	PKNode *P2 = [self nearestNeighborWithPreVisitor:NULL
										 postVisitor:NULL
												node:P1
											 visited:visited];
	
	// Origin is already determined.
	P2.isOrigin = NO;

	// Set the output dimensions for this node to be 3-dimensional.
	P2.numberOfDimensions = numberOfDimensions;
	
	/**
	 *	** Cartesian coordinates in 2-dimensions.
	 *	Given any two points P1 and P2 in the 3-dimensional space, the distance between them is given by:
	 *	distance(P1, P2) = sqrt((P2.x - P1.x)^2 + (P2.y - P1.y)^2);
	 *
	 *	** Cartesian coordinates in a 3-dimensional space.
	 *	Given any two points P1 and P2 in 3-dimensions, the distance between them is given by:
	 *	distance(P1, P2) = sqrt((P2.x - P1.x)^2 + (P2.y - P1.y)^2 + (P2.z - P1.z)^2);
	 */
	double cosineAlpha = 0.0;
	double sineAlpha = 0.0;
	
	// distance(P0, P2);
	double P0P2 = [self.graph edgeFromIndex:P0.number toIndex:P2.number].weight.doubleValue;
	
	// distance(P1, P2);
	double P1P2 = [self.graph edgeFromIndex:P1.number toIndex:P2.number].weight.doubleValue;
	
	/**
	 *	We consider the Law of Cosines and update the coordinates accordingly.
	 *
	 *	P1P2^2 = P0P1^2 + P0P2^2 - 2 * P0P1 * P0P2 * cosineAlpha;
	 *
	 *	Hence,
	 *	cosineAlpha = P0P1^2 + P0P2^2 - P1P2^2 / 2 * P0P1 * P0P2;
	 */
	cosineAlpha = ((pow(P0P1, 2.0) + pow(P0P2, 2.0) - pow(P1P2, 2.0))
				   /
				   (2.0 * P0P1 * P0P2));
	
	// The law of Sines.
	sineAlpha = sqrt(1.0 - pow(cosineAlpha, 2.0));
	
	// Calculate coords for P2.
	[P2 replacePositionAtIndex:0 withObject:@(P0P2 * cosineAlpha)];
	[P2 replacePositionAtIndex:1 withObject:@(P0P2 * sineAlpha)];
	[P2 updatePosition];
	
	@try { // Adding the new node to the projection model.
		
		// Does not throw an exception at this stage.
		[PPGraph insertNode:P2 projection:self.projection];
	}
	@catch (NSException *exception) {
		
		// Handle the error/exception.
		[self handleException:exception];
	}
	@finally {
		
		// Update the log.
//		[log appendFormat:@"<li>We then map <font color=#FFFF00><strong>%@</strong></font> "
//		 "corresponding to point <strong>P[%lu]</strong>,<br />"
//		 "<font color=#AAFFAA><strong>%@</strong></font>", P2.identifier, nodeIdx, P2];
		
		// Increment the index counter.
		++nodeIdx;
	}
	
	/**
	 *	At this stage, we assume a successful building of an orthonormal space and as such,
	 *	we have placed three points, P0, P1, and P2 respectfully in an N-dimensional space.
	 *
	 *	For the case of equality (numberOfNodes = N),
	 *	the process is reduced down to the 2-dimensional PP approach (where N = 2),
	 *	where N denotes the number of dimensions of our measured space.
	 *
	 *  Now, we set the (i)th node as the (i)th nearest node to origin.
	 *	Find the next nearest node to the seed node (is this the case now?).
	 */
	PKNode *Pi = nil;
	
	/**
	 *  Components P(i,j), for i = 1, ..., N and j = 0, ..., i − 1, form a set of N(N + 1) / 2 unknowns,
	 *	and are therefore determined first.
	 */

	// We consider the first "N" points to define a coordinate system in N-dimensions.
	if (numberOfNodes > numberOfDimensions) {
		
		// Find the (i)th nearest neighbor to P2.
		Pi = [self nearestNeighborWithPreVisitor:NULL
									 postVisitor:NULL
											node:P2
										 visited:visited];

		// Origin is already determined.
		Pi.isOrigin = NO;

		// Set the output dimensions for this node to be N-dimensional.
		Pi.numberOfDimensions = numberOfDimensions;
		
		/**
		 *	With 2-dimensions, the first 3 points are used to define the 2-dimensional system.
		 *	P0 marked the origin of all coordinates. Points P1 and P2 further defined both x- and y-axes respectfully.
		 *
		 *	With 3-dimensions, the first 4 points are used to define the 3-dimensional system.
		 *	P0 marked the origin. P1, P2 and P3 defined the x-, y- and z-axes respectfully.
		 *
		 *	Therefore,
		 *	In an N-dimensions, the first (N + 1) points are used to define the N-dimensional system.
		 *	P0 marked the origin. P1, P2, ..., P(N) defined the N-axial directions of N.
		 *
		 *	We start by establishing a reference to the node at index "i" to work with,
		 *	where "i" ranges from the fourth point (i = 3) to N (assuming that N < numberOfNodes − 1).
		 */
		for (NSInteger dimension = 3;
			 dimension <= numberOfDimensions;
			 ++dimension) {
			
			// Establish a positions array for Pi.
			id<PKArrayDelegate> positions = [PKArray arrayWithLength:numberOfDimensions];
			
			// Initialize the positions array with 0s.
			for (NSUInteger j = 0;
				 j < numberOfDimensions;
				 ++j) {
    
				[positions replaceObjectAtIndex:j withObject:@(0.0)];
			}
			
			// distance(P0, Pi);
			double P0Pi = [self.graph edgeFromIndex:P0.number toIndex:Pi.number].weight.doubleValue;
			
			// Compute the positional component "k" of Pi.
			for (NSInteger k = 0;
				 k <= dimension - 2;
				 ++k) {
				
				// Get a reference to the node at (k + 1).
				PKNode *nodeAtK1 = [PPGraph nodeAtIndex:(k + 1)];
				
				// Establish a reference to PiPk.
				double kOfPi = [[nodeAtK1 positionAtIndex:k] doubleValue];
				
				// Establish the two sums.
				double sum1 = 0.0;
				double sum2 = 0.0;
				
				// Iterating from "j" to "k".
				for (NSInteger j = 0;
					 j <= k;
					 ++j) {
					
					// Compute the positional component "j" of Pi.
						 double jOfPi = [[nodeAtK1 positionAtIndex:j] doubleValue];
					
					// Accumulate "sum1".
						 sum1 += pow(jOfPi, 2.0);
					
					// Establish the j'th component.
					double positionAtJ = [[positions objectAtIndex:j] doubleValue];
					
					// Accumulate "sum2".
					sum2 += positionAtJ * jOfPi;
				}
				
				// distance(Pk, Ni);
				double PkPi = [self.graph edgeFromIndex:nodeAtK1.number
												toIndex:Pi.number].weight.doubleValue; // (k + 1).
				
				// Update Pi's "k" position.
				[positions replaceObjectAtIndex:k
									 withObject:@((sum1 - pow(PkPi, 2.0) + pow(P0Pi, 2.0) - 2.0 * sum2) / (2.0 * kOfPi))];
			}
			
			// Establish "sum1".
			double sum1 = pow(P0Pi, 2.0);
			
			// Iterating from "j = 0" to "N - 2".
			for (NSInteger j = 0;
				 j <= numberOfDimensions - 2;
				 ++j) {
				
				// Compute the j'th positional component.
				double jOfPi = [[positions objectAtIndex:j] doubleValue];
				
				// Update "sum1".
				sum1 -= pow(jOfPi, 2.0);
			}
			
			// Checksum (avoid squaring negative values).
			if (sum1 < 0.0) {
				
				NSLog(@"Warning: sum1 = %g", sum1);
				sum1 = fabs(sum1);
			}
			
			// Update Pi's position.
			[positions replaceObjectAtIndex:(dimension - 1) withObject:@(sqrt(sum1))];
			
			Pi.positions = positions;
			
			// Update Pi's position vector.
			[Pi updatePosition];
			
			@try { // Adding the new node to the projection model.
				
				// Does not throw an exception at this stage.
				[PPGraph insertNode:Pi projection:self.projection];
			}
			@catch (NSException *exception) {
				
				// Handle the error/exception.
				[self handleException:exception];
			}
			@finally {
				
				// Update the log.
//				[log appendFormat:@"<li>Set <font color=#FFFF00><strong>%@</strong></font>, as the "
//				 "(<strong>%lu</strong>)th nearest neighbor,<br /><font color=#AAFFAA><strong>%@</strong></font>",
//				 Pi.identifier, nodeIdx, Pi];
				
				// Increment the index counter.
				++nodeIdx;

				// Find the (i)th nearest neighbor to P(i - 1).
				Pi = [self nearestNeighborWithPreVisitor:NULL
											 postVisitor:NULL
													node:Pi
												 visited:visited];
				
				// Origin is already determined.
				Pi.isOrigin = NO;

				// Set the output dimensions for this node to be N-dimensional.
				Pi.numberOfDimensions = numberOfDimensions;
			}
		}
	}

	/**
	 *	The remaining NN points are computed as tetrahedra with base P0P1P2.
	 */
	while (Pi) {
		
		for (NSInteger dimension = numberOfDimensions + 1;
			 dimension < numberOfNodes;
			 ++dimension) {
			
			// Establish a positions array for Pi.
			id<PKArrayDelegate> positions = [PKArray arrayWithLength:numberOfDimensions];
			
			// Initialize the positions array with 0s.
			for (NSUInteger j = 0;
				 j < numberOfDimensions;
				 ++j) {
    
				[positions replaceObjectAtIndex:j withObject:@(0.0)];
			}
			
			// distance(P0, Pi);
			double P0Pi = [self.graph edgeFromIndex:P0.number toIndex:Pi.number].weight.doubleValue;
			
			// Compute the positional component "k" of Pi.
			for (NSInteger k = 0;
				 k <= numberOfDimensions - 1;
				 ++k) {
				
				// Get a reference to the node at (k + 1).
				PKNode *nodeAtK1 = [PPGraph nodeAtIndex:(k + 1)];
				
				// Establish a reference to PiPk.
				double kOfPi = [[nodeAtK1 positionAtIndex:k] doubleValue];
				
				// Establish the two sums.
				double sum1 = 0.0;
				double sum2 = 0.0;
				
				// Iterating from "j" to "k".
				for (NSInteger j = 0;
					 j <= k;
					 ++j) {
					
					// Compute the positional component "j" of Pi.
						 double jOfPi = [[nodeAtK1 positionAtIndex:j] doubleValue];
					
					// Accumulate "sum1".
						 sum1 += pow(jOfPi, 2.0);
					
					// Establish the j'th component.
					double positionAtJ = [[positions objectAtIndex:j] doubleValue];
					
					// Accumulate "sum2".
					sum2 += positionAtJ * jOfPi;
				}
				
				// distance(Pk, Ni);
				double PkPi = [self.graph edgeFromIndex:nodeAtK1.number
												toIndex:Pi.number].weight.doubleValue; // (k + 1).
				
				// Update Pi's "k" position.
				[positions replaceObjectAtIndex:k
									 withObject:@((sum1 - pow(PkPi, 2.0) + pow(P0Pi, 2.0) - 2.0 * sum2) / (2.0 * kOfPi))];
			}
			
			// Establish "sum1".
			double sum1 = pow(P0Pi, 2.0);
			
			// Iterating from "j = 0" to "N - 2".
			for (NSInteger j = 0;
				 j <= numberOfDimensions - 2;
				 ++j) {
				
				// Compute the j'th positional component.
				double jOfPi = [[positions objectAtIndex:j] doubleValue];
				
				// Update "sum1".
				sum1 -= pow(jOfPi, 2.0);
			}
			
			// Checksum (avoid squaring negative values).
			if (sum1 < 0.0) {
				
				NSLog(@"Warning: sum1 = %g", sum1);
				sum1 = fabs(sum1);
			}
			
			// Update Pi's position.
			[positions replaceObjectAtIndex:(numberOfDimensions - 1) withObject:@(sqrt(sum1))];
			
			Pi.positions = positions;
			
			// Update Pi's position vector.
			[Pi updatePosition];
			
			// Get a reference to the node at index (numberOfDimensions).
			PKNode *Pn = [PPGraph nodeAtIndex:numberOfDimensions];
			
			// distance(Pn, Pi);
			double PnPi = [self.graph edgeFromIndex:Pn.number // numberOfDimensions | (numberOfDimensions + 1).
											toIndex:Pi.number].weight.doubleValue;
			
			// distance(Pn, Pi+);
			double computedPnPi = (self.projection.distanceMetric == PKEuclidean) ?
			[[Pn positions] euclideanDistance:Pi.positions] :
			[[Pn positions] manhattanDistance:Pi.positions];
			
			// Get a copy of Pi.
			PKNode *flippedPi = Pi.clone;
			
			// Negate the last coordinate.
			[flippedPi replacePositionAtIndex:(numberOfDimensions - 1)
								   withObject:@(-[[Pi positionAtIndex:(numberOfDimensions - 1)] doubleValue])];
			
			// Update flippedPi's position vector.
			[flippedPi updatePosition];
			
			// distance(Pn, Pi-);
			// newFlippedPnPi := DistancenD(PointNumber[NrDimensions + 1], PointNumber[i]);
			double flippedPnPi =
			(self.projection.distanceMetric == PKEuclidean) ?
			[[Pn positions] euclideanDistance:flippedPi.positions] :
			[[Pn positions] manhattanDistance:flippedPi.positions];

			/**
			 *	We consider all possible outside edges P0 and Pn and choose Pi using either
			 * "Minimum Perimeter" or "Minimum Area" properties.
			 */
			if (self.minimumPerimeter ||
				self.minimumArea) {
				
				// distance(P0, Pn);
				double computedP0Pn = (self.projection.distanceMetric == PKEuclidean) ?
				[[P0 positions] euclideanDistance:Pn.positions] :
				[[P0 positions] manhattanDistance:Pn.positions];
				
				// distance(P0, Pi+);
				double computedP0Pi = (self.projection.distanceMetric == PKEuclidean) ?
				[[P0 positions] euclideanDistance:Pi.positions] :
				[[P0 positions] manhattanDistance:Pi.positions];

				// distance(P0, Pi-);
				double flippedP0Pi = (self.projection.distanceMetric == PKEuclidean) ?
				[[P0 positions] euclideanDistance:flippedPi.positions] :
				[[P0 positions] manhattanDistance:flippedPi.positions];
				
				// Calculate the semi-perimeter of the first triangle as:
				// s = (computedP0Pn + computedPnPi + computedP0Pi) / 2.
				double sp1 = (computedP0Pn + computedPnPi + computedP0Pi) / 2.0;
				
				// Calculate the semi-perimeter of the second triangle as:
				// s = (computedP0Pn + PnPi- + P0Pi-) / 2.
				double sp2 = (computedP0Pn + flippedPnPi + flippedP0Pi) / 2.0;
				
				// We consider all possible outside edges P0 and Pn and choose Pi using the "Minimum Area" property.
				if (self.minimumArea) {
					
					// Compute the area of the first triangle (computedP0Pn, computedPnPi, computedP0Pi).
					double aComputedP0PnPi = sqrt(sp1 * (sp1 - computedP0Pn) * (sp1 - computedPnPi) * (sp1 - computedP0Pi));

					// Compute the area of the second triangle (computedP0Pn, flippedPnPi, flippedP0Pi).
					double aFlippedP0PnPi = sqrt(sp2 * (sp2 - computedP0Pn) * (sp2 - flippedPnPi) * (sp2 - flippedP0Pi));

					/**
					 *	If area of second < area of first,
					 *	then we affirm the flipping.
					 */
					if (aFlippedP0PnPi < aComputedP0PnPi) {
						
						// Set the coords for the flipped copy of Pi, having Pi.z in the "negative" z-domain.
						// Negate the last coordinate.
						[Pi replacePositionAtIndex:(numberOfDimensions - 1)
										withObject:@(-[[Pi positionAtIndex:(numberOfDimensions - 1)] doubleValue])];
						
						// Update Pi's position vector.
						[Pi updatePosition];
						
						// Update the flipped status.
						Pi.flipped = YES;
					}
					
				} else { // We consider all possible outside edges P0 and Pn and choose Pi using the "Minimum Perimeter" property.
					
					/**
					 *	If semi-perimeter of second < semi-perimeter of first,
					 *	then we affirm the flipping.
					 */
					if (sp2 < sp1) {
						
						// Set the coords for the flipped copy of Pi, having Pi.z in the "negative" z-domain.
						// Negate the last coordinate.
						[Pi replacePositionAtIndex:(numberOfDimensions - 1)
										withObject:@(-[[Pi positionAtIndex:(numberOfDimensions - 1)] doubleValue])];
						
						// Update Pi's position vector.
						[Pi updatePosition];
						
						// Update the flipped status.
						Pi.flipped = YES;
					}
				}
				
			} else { // We consider all possible outside edges P0 and Pn and choose Pi using the "Minimum Distance" property.
				
				/**
				 *	If ABS(PnPi - newFlippedPnPi) < ABS(PnPi - newPnPi),
				 *	then we affirm the flipping.
				 */
				if (fabs(PnPi - flippedPnPi) < fabs(PnPi - computedPnPi)) {
					
					// Set the coords for the flipped copy of Pi, having Pi.z in the "negative" z-domain.
					// Negate the last coordinate.
					[Pi replacePositionAtIndex:(numberOfDimensions - 1)
									withObject:@(-[[Pi positionAtIndex:(numberOfDimensions - 1)] doubleValue])];
					
					// Update Pi's position vector.
					[Pi updatePosition];
					
					// Update the flipped status.
					Pi.flipped = YES;
				}
			}
			
			@try { // Adding the new node to the projection model.
				
				// Does not throw an exception at this stage.
				[PPGraph insertNode:Pi projection:self.projection];
			}
			@catch (NSException *exception) {
				
				// Handle the error/exception.
				[self handleException:exception];
			}
			@finally {
				
				// Update the log.
//				[log appendFormat:@"<li>Set <font color=#FFFF00><strong>%@</strong></font>, as the "
//				 "(<strong>%lu</strong>)th nearest neighbor,<br /><font color=#AAFFAA><strong>%@</strong></font>",
//				 Pi.identifier, nodeIdx, Pi];
				
				// Increment the index counter.
				++nodeIdx;
				
				// Find the (i)th nearest neighbor to P(i - 1).
				Pi = [self nearestNeighborWithPreVisitor:NULL
											 postVisitor:NULL
													node:Pi
												 visited:visited];
				
				// Origin is already determined.
				Pi.isOrigin = NO;

				// Set the output dimensions for this node to be N-dimensional.
				Pi.numberOfDimensions = numberOfDimensions;
			}
		}
	}
	
	// Unordered list (fold).
//	[log appendString:@"</ul>"];
	
	/**
	 *	** Projection Error **
	 *
	 *	In order to quantive the "goodness" of the projection,
	 *	Sammon [Sam69] states a cost function which is labelled as Sammon's stress in the literature.
	 *
	 *	** Minimizing the Projection Error **
	 *
	 *	TP2 aims to minimize this function,
	 *	and the projection problem can be seen as a function minimizing problem which can't be solved in a closed form and can only be made approximately.
	 *	For these kind of problems, several (iterative) algorithms exists...
	 *
	 *  At this stage, if we are to iterate through the list of nodes to correct the positions,
	 *	Then we attempt to utilize Sammon's stress as means for performing the corrections.
	 */
	if (self.numberOfIterations > 1) {
		
		// Establish the precalculated distance-matrix from the new graph (edge matrix).
		id<PKMatrixDelegate> distanceMatrix = [self.graph edgeMatrix];
		
		// Establish the indices arrays.
		self.indicesI = [PKIntegerArray arrayWithLength:numberOfNodes];
		self.indicesJ = [PKIntegerArray arrayWithLength:numberOfNodes];
		
		// Attempt to copy all node numbers to both arrays.
		for (PKNode *node in PPGraph.nodes) {
			
			[self.indicesI replaceIntegerAtIndex:node.number
									 withInteger:node.number];
		}
		
		// Copy indicesI into indicesJ.
		self.indicesJ = self.indicesI.copy;
		
		// Perform enumerations of the (heuristic) algorithm.
		// The heart of the projection algorithm:
		// Runs all the iterations and thus create the mapping.
		for (NSInteger idx = 0;
			 idx < self.numberOfIterations;
			 ++idx) {
			
			// In order to pick the vectors randomly, we may quite often use an index-array that is shuffled.
			// The shuffling is done by the Fisher-Yates-Shuffle algorithm.
			// We therefore shuffle both arrays using this algorithm.
			[self.indicesI shuffle];
			[self.indicesJ shuffle];
			
			for (NSUInteger i = 0;
				 i < self.indicesI.length;
				 i++) {
				
				// Establish the i'th index.
				NSUInteger indexI = [self.indicesI integerAtIndex:i];
				
				// Establish a reference to the currently picked head node.
				PKNode *head = [PPGraph nodeAtIndex:indexI];
				
				// distances at _indicesI(i);
				id<PKArrayDelegate> distancesI = [distanceMatrix arrayAtRowIndex:indexI];
				
				for (NSUInteger j = 0;
					 j < self.indicesJ.length;
					 j++) {
					
					// Establish the j'th index.
					NSUInteger indexJ = [self.indicesJ integerAtIndex:j];
					
					// Establish a reference to the currently picked head node.
					PKNode *tail = [PPGraph nodeAtIndex:indexJ];
					
					// Skip over identical coordinates.
					if (indexI == indexJ)
						continue;
					
					// Establish the original distance (Dij).
					double Dij = [[distancesI objectAtIndex:indexJ] doubleValue];
					
					// Establish the projection distance (dij).
					double dij = (self.projection.distanceMetric == PKEuclidean) ?
					[head.positions euclideanDistance:tail.positions] :
					[head.positions manhattanDistance:tail.positions];
					
					// Avoid division by 0.
					if (dij == 0.0)
						dij = 1E-10;
					
					// Establish the difference (delta: uppercase Δ, lowercase δ).
					double delta = self.lambda * (Dij - dij) / dij;
					
					for (NSUInteger k = 0;
						 k < tail.positions.length;
						 k++) {
						
						// Establish the three k'th coordinates for both head and tail nodes.
						double pI = [[head positionAtIndex:k] doubleValue];
						double pJ = [[tail positionAtIndex:k] doubleValue];
						
						// Establish the correction value.
						double correction = delta * (pI - pJ);
						
						// Adjust both coordinates.
						pI += correction;
						pJ -= correction;
						
						// Update the k'th position with the corrected values.
						[head replacePositionAtIndex:k withObject:@(pI)];
						[tail replacePositionAtIndex:k withObject:@(pJ)];
						
						// Update the position vectors.
						[head updatePosition];
						[tail updatePosition];
					}
				}
			}
			
			// Reduce λ monotonically.
			[self reduceLambda];
		}
	}
	
	// Map the Nearest Neighbor (NN) edges, starting form P0.
//	if (self.mapNNC) {
//		
//		// Iterate each head node.
//		for (NSUInteger idx = 0;
//			 idx < numberOfNodes;
//			 ++idx) {
//			
//			// Get a reference to the head entry.
//			PKNode *PPNode = [PPGraph nodeAtIndex:idx];
//			
//			// Skip the start index.
//			if (PPNode.number != self.startIndex) {
//				
//				// Get a reference to the tail entry.
//				PKNode *predecessorNode = [PPGraph nodeAtIndex:idx - 1];
//				
//				@try { // Adding the new edge to the projection model.
//					
//					// Add an edge based on current node number and its predecessor.
//					[PPGraph addEdgeFromIndex:PPNode.number
//									  toIndex:predecessorNode.number
//							isNearestNeighbor:YES
//									   weight:@((self.distanceMetric == PKEuclidean) ?
//					 [PPNode.positions euclideanDistance:predecessorNode.positions] :
//					 [PPNode.positions manhattanDistance:predecessorNode.positions])
//								   projection:self.projection];
//				}
//				@catch (NSException *exception) {
//					
//					// Handle the error/exception.
//					[self handleException:exception];
//				}
//			}
//		}
//	}
	
	// Map the triangle edges.
//	if (self.mapEmanatingEdges) {
//		
//		for (PKNode *PPNode in PPGraph.nodes) {
//			
//			// Skip the start index.
//			if (PPNode.number != self.startIndex) {
//				
//				// Make sure we do not attempt to add duplicate edges.
//				if (![PPGraph isEdgeFromIndex:PPNode.number
//									  toIndex:P0.number]) {
//					
//					// Add an edge based on current node number and its predecessor.
//					[PPGraph addEdgeFromIndex:PPNode.number
//									  toIndex:P0.number
//							isNearestNeighbor:NO
//									   weight:@((self.distanceMetric == PKEuclidean) ?
//					 [PPNode.positions euclideanDistance:P0.positions] :
//					 [PPNode.positions manhattanDistance:P0.positions])
//								   projection:self.projection];
//				}
//				
//				// Make sure we do not attempt to add duplicate edges.
//				if (![PPGraph isEdgeFromIndex:PPNode.number
//									  toIndex:P1.number]) {
//					
//					// Add an edge based on current node number and its predecessor.
//					[PPGraph addEdgeFromIndex:PPNode.number
//									  toIndex:P1.number
//							isNearestNeighbor:NO
//									   weight:@((self.distanceMetric == PKEuclidean) ?
//					 [PPNode.positions euclideanDistance:P1.positions] :
//					 [PPNode.positions manhattanDistance:P1.positions])
//								   projection:self.projection];
//				}
//			}
//		}
//	}

	// Horizontal line.
	[log appendString:@"<hr><br />"];
	
	// Log the correction process.
	if (self.numberOfIterations > 1) {
		
		// Append the current record to the results array.
		[results replaceObjectAtIndex:1 withObject:@(timeSinceOperation - CFAbsoluteTimeGetCurrent())];

		// Report the reordered list of nodes after performing the iterations.
		[log appendString:@"<strong><font color=\"#FFFFFF\">After correction:</font></strong><br />"];
		
		// Unordered list.
		[log appendString:@"<ul>"];
		
	} else {
		
		// Append the current record to the results array.
		[results replaceObjectAtIndex:1 withObject:@(0.0)];
	}
	
	// Log the correction process.
	if (self.numberOfIterations > 1) {
		
		// Unordered list (fold).
		[log appendString:@"</ul>"];
		
		// Header.
		[log appendString:@"<strong><font color=\"#FFFFFF\">Iterations:</font></strong><br />"];
		
		// Unordered list.
		[log appendString:@"<ul>"];
		
		// Number of iterations.
		[log appendFormat:@"<li><strong><font color=\"#00FF00\">%lu</font></strong> iterations", self.iteration];
		
		// Append the current record to the results array.
		[results replaceObjectAtIndex:2 withObject:@(self.lambda)];

		// Time in milliseconds.
		[log appendFormat:@"<li><strong>λ = <font color=\"#00FF00\">%.4g</font></strong>", self.lambda];
		
		// Unordered list (fold).
		[log appendString:@"</ul>"];
		
		// Horizontal line.
		[log appendString:@"<hr><br />"];
	}
	
	// Append the current record to the results array.
	[results replaceObjectAtIndex:2 withObject:@(self.lambda)];
	
	// Append the current record to the results array.
	[results replaceObjectAtIndex:3 withObject:(self.minimumDistance ? @"YES" : @"NO")];
	[results replaceObjectAtIndex:4 withObject:(self.minimumPerimeter ? @"YES" : @"NO")];
	[results replaceObjectAtIndex:5 withObject:(self.minimumArea ? @"YES" : @"NO")];

	// Call our completion handler with the result of our processing.
	if (![self isCancelled]) {
		
		// Pass a successful projection operation to the post-processing handler.
		if (self.completionHandler)
			self.completionHandler(PPGraph,
								   nil,
								   results,
								   nil,
								   self.startIndex,
								   CFAbsoluteTimeGetCurrent() - timeSinceOperation,
								   log);
		
	} else { // Failed or cancelled.
		
		NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
											 code:kPKErrorCode
										 userInfo:@{NSLocalizedDescriptionKey:@"Algorithm failed or cancelled."}];
		
		// Pass a failed operation to the error handler.
		if (self.errorHandler)
			self.errorHandler(error);
	}
}

@end
