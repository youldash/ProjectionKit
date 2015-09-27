//
//  PKGeometricCoordinatizer.m
//  ProjectionKit
//
//  Copyright (c) 2015 Mustafa Youldash. All rights reserved.
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

#import "PKGeometricCoordinatizer.h"

@implementation PKGeometricCoordinatizer

#pragma mark -
#pragma mark Creating

/**
 *	The Geometric Coordinatizer (initial stage).
 *	Returns a reordered graph of a given "unordered" graph.
 *
 *	@param	graph				An edge-weighted, undirected graph.
 *	@param	start				A starting index.
 *	@param	finish				A finishing index (used in skinning mode).
 *	@param	flag				A reordering flag.
 *	@param	projectionType		A projection type (2D/3D).
 *  @param	completionHandler	A completion handler.
 *  @param	errorHandler		An error handler.
 *
 *	@return	The new algorithm operation.
 */
+ (instancetype)coordinatizerWithGraph:(id<PKGraphDelegate>)graph
							 fromIndex:(NSUInteger)start
							   toIndex:(NSUInteger)finish
							   reorder:(BOOL)flag
						projectionType:(PKProjectionType)projectionType
					 completionHandler:(PKCompletionBlock)completionHandler
						  errorHandler:(PKErrorBlock)errorHandler
{
	// Immutable coordinatizer operation, just return a new reference to itself (retained automatically by ARC).
	return [[[self class] alloc] initWithGraph:graph
									 fromIndex:start
									   toIndex:finish
									   reorder:flag
								projectionType:projectionType
							 completionHandler:completionHandler
								  errorHandler:errorHandler];
}

#pragma mark -
#pragma mark Initializing

/**
 *	Designated initializer.
 *	Called when an instance is passed to an NSOperationQueue.
 *
 *	@param	graph				An edge-weighted, undirected graph.
 *	@param	start				A starting index.
 *	@param	finish				A finishing index (used in skinning mode).
 *	@param	flag				A reordering flag.
 *	@param	projectionType		A projection type (2D/3D).
 *  @param	completionHandler	A completion handler.
 *  @param	errorHandler		An error handler.
 *
 *	@return	The new algorithm operation.
 */
- (instancetype)initWithGraph:(id<PKGraphDelegate>)graph
					fromIndex:(NSUInteger)start
					  toIndex:(NSUInteger)finish
					  reorder:(BOOL)flag
			   projectionType:(PKProjectionType)projectionType
			completionHandler:(PKCompletionBlock)completionHandler
				 errorHandler:(PKErrorBlock)errorHandler
{
	// Immutable coordinatizer operation, just return a new reference to itself (retained automatically by ARC).
	self = [super init];
	
	if (self) {
		
		// Initialization code.
		self.name = @"Geometric Coordinatizer";
		self.graph = graph;
		self.startIndex = start;
		self.finishIndex = finish;
		self.projectionType = projectionType;
		self.completionHandler = completionHandler;
		self.errorHandler = errorHandler;
		
		// Pass the reorder flag.
		_reorderNodes = flag;
	}
	
	// Retun this coordinatizer operation.
	return self;
}

#pragma mark -
#pragma mark Operating

/**
 *  Returns a reordering of nodes (graph) prior running the GC algorithm.
 *
 *  @param numberOfNodes		The number of nodes.
 *  @param numberOfDimensions	The number of dimensions.
 *
 *  @return A temporary graph used for storing nodes only.
 */
- (id<PKGraphDelegate>)reorderGraphWithLength:(NSUInteger)numberOfNodes
						   numberOfDimensions:(NSUInteger)numberOfDimensions
{
	// Establish a graph storing nodes.
	id<PKGraphDelegate> graph = [[PKDigraphAsMatrix alloc] initWithIdentifier:@"Nodes Digraph" length:numberOfNodes];
	
	// An array of sums.
	PKArray *sums = [[PKArray class] arrayWithLength:numberOfNodes];
	
	// The i'th sum, sums[i], represents the set of sums for each linked list, adjacencyLists[i].
	for (NSUInteger idx = 0;
		 idx < numberOfNodes;
		 ++idx) {
		
		[sums replaceObjectAtIndex:idx withObject:@(0.0)];
	}
	
	// A priority queue used in conjunction with key value pairs.
	PKBinaryHeap *queue = [[PKBinaryHeap alloc] initWithCapacity:numberOfNodes];
	
	// Establish a reference to the graph nodes.
	id<PKEnumerableDelegate> nodes = self.graph.nodes;
	
	// Calculate node distances.
	for (PKNode *head in nodes) {
		
		// Establish the current head number.
		NSUInteger headNumber = head.number;
		
		for (PKNode *tail in nodes) {
			
			// Establish the current tail number.
			NSUInteger tailNumber = tail.number;
			
			// Get the current weight.
			NSNumber *weight = [self.graph edgeFromIndex:headNumber toIndex:tailNumber].weight;
			
			// Get the recorded sum, corresponding to the i'th adjacency list.
			double sum = [[sums objectAtIndex:headNumber] doubleValue];
			
			// Add the current distance record to the sums array (i'th).
			sum += weight.doubleValue;
			
			// Update the total sum of distances.
			[sums replaceObjectAtIndex:headNumber withObject:@(sum)];
		}
		
		// Enqueue a new key value pair (having the sum of distances as key, and the head node as value).
		[queue enqueue:[PKKeyValuePair pairWithKey:[sums objectAtIndex:headNumber]
											 value:[self.graph nodeAtIndex:headNumber]]];
	}
	
	/**
	 *  For each site Si, we compute the sum of the distances from that site to all other sites and we denote this as Di.
	 *	The site with the smallest/largest value of Di is the most/least "connected" of all the sites,
	 *	and it is chosen as the first site in the reordering, that is, R[1].
	 *	For site R[2], we select the site with the second smallest/largest value of Di,
	 *	for site R[3], we select the site with the third smallest/largest value of Di, and so forth.
	 *	It is conjectured that the second of these reorderings will reduce the absolute numerical errors in applying the algorithm.
	 *	This second reordering, is therefore, assumed in the algorithm.
	 *
	 *	For each table entry, setup a new algorithm entry record, based on the current node count.
	 */
	while (![queue isEmpty]) {
		
		// Dequeue the smallest node.
		PKKeyValuePair *pair = [queue dequeueMinimum];
		
		// Get a reference to the current node in the pair.
		PKNode *node = pair.value;

		// Set the output dimensions for this node to be N-dimensional.
		node.numberOfDimensions = numberOfDimensions;
		
		@try { // Adding the new node to the projection model.
			
			// Does not throw an exception at this stage.
			[graph insertNode:node projection:self.projection];
		}
		@catch (NSException *exception) {
			
			// Handle the error/exception.
			[self handleException:exception];
		}
	}
	
	// Retun the graph.
	return graph;
}

#pragma mark -
#pragma mark NSOperation

/**
 *	Invokes the chosen algorithm...
 *
 *	Called when an instance is passed to an NSOperationQueue.
 *
 *  Constructs a reordered graph using the GC algorithm.
 *	Constructs a minimum spanning tree using the other algorithms.
 */
- (void)main
{
	// Save the time prior operation execution.
	CFAbsoluteTime timeSinceOperation = CFAbsoluteTimeGetCurrent();
	
	// Return a log in HTML format, showing results.
	NSMutableString *log = [NSMutableString string];
	
	/**
	 *	Instantiate a new reordered graph by passing a seed note.
	 *	Edges will be sorted according to their designated weights.
	 *
	 *  The reordering is represented by a 1D array R[i] so that in place of the original ordering of the sites 1, 2, 3, ..., N,
	 *	we have the new ordering denoted R[1], R[2], R[3], ..., R[N].
	 */
	
	// Get a reference to the current number of nodes in the passing graph.
	// If the finishing index is > 0 then this tells us that we are skinning the graph.
	NSUInteger numberOfNodes = self.finishIndex > 0 ? self.finishIndex + 1 : self.graph.numberOfNodes;
	
	// Get a reference to the current number of dimensions.
	NSUInteger numberOfDimensions = self.projection.numberOfDimensions;
	
	// A GC graph, will be passed to the completion handler.
	id<PKGraphDelegate> GCGraph = [[PKDigraphAsMatrix alloc] initWithIdentifier:@"GC Digraph" length:numberOfNodes];
	
	// A temporary digraph used for storing nodes only.
	// Only apply a reordering of nodes when user decides!
	id<PKGraphDelegate> graph = _reorderNodes ?
	[self reorderGraphWithLength:numberOfNodes
			  numberOfDimensions:numberOfDimensions] : self.graph;
	
	// Reference index used to track the current node being processed.
	NSInteger nodeIdx = 0;
	
	// Header.
	[log appendFormat:
	 @"<strong><font color=\"#FFFFFF\">Coordinatizing %lu Points in %lu-Dimensions:</font></strong><br />",
	 numberOfNodes,
	 numberOfDimensions];
	
	// Unordered list.
	[log appendString:@"<ul>"];
	
	// Establish a node enumerator.
	id<PKEnumeratorDelegate> nodeEnumerator = [graph nodeEnumerator];

	// Here, we find the unique seed node (root).
	// We choose root as the head of the first edge (E0) in the list.
	PKNode *P0 = [nodeEnumerator nextObject];
	
	// Set its number as the starting index.
	self.startIndex = P0.number;
	
	// Set the output dimensions for this node to be N-dimensional.
	P0.numberOfDimensions = numberOfDimensions;
	
	// The origin of the N-dimensional Cartesian space can be selected arbitrarily.
	// Therefore, set the first point P[0] as located at the origin.
	P0.isOrigin = YES;
	P0.color = self.projection.flipColors ? [PKNode seedColorOverWhite] : [PKNode seedColorOverBlack];
	
	@try { // Adding the new node to the projection model.
		
		// Does not throw an exception at this stage.
		[GCGraph insertNode:P0 projection:self.projection];
	}
	@catch (NSException *exception) {
		
		// Handle the error/exception.
		[self handleException:exception];
	}
	@finally {
		
		// Update the log.
		[log appendFormat:@"<li>Set the first point <strong>P[%lu]</strong> as located at the origin,<br />"
		 "<font color=#AAFFAA><strong>%@</strong></font>", nodeIdx, P0];
		
		// Increment the index counter.
		++nodeIdx;
	}
	
	/**
	 *	Next, we find the nearest node to the seed node...
	 *	Set it as the nearest node to origin, and map its direction towards the positive region of the X axis.
	 *
	 *  The direction of the x-axis of the 2D cartesian space can be selected arbitrarily.
	 *	Therefore, set the line from site R[0] to site R[1].
	 *	That is, from P1 to P2 as the x-axis direction, to maintain distance scales.
	 */
	PKNode *P1 = [nodeEnumerator nextObject];
	
	// Origin is already determined.
	P1.isOrigin = NO;
	
	// Set the output dimensions for this node to be N-dimensional.
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
		[GCGraph insertNode:P1 projection:self.projection];
	}
	@catch (NSException *exception) {
		
		// Handle the error/exception.
		[self handleException:exception];
	}
	@finally {
		
		// Update the log.
		[log appendFormat:@"<li>Set the line from point <strong>P[%lu]</strong> to point <strong>P[%lu]</strong>,<br />i.e. "
		 "from <font color=#FFFF00><strong>%@</strong></font> to <font color=#FFFF00><strong>%@</strong></font> "
		 "as the x-axis direction,<br />"
		 "<font color=#AAFFAA><strong>%@</strong></font>", P0.number, P1.number, P0.identifier, P1.identifier, P1];
		
		// Increment the index counter.
		++nodeIdx;
	}
	
	/**
	 *	Now consider 2-dimensional coordinates for the point P2 corresponding to site R[2].
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
	PKNode *P2 = [nodeEnumerator nextObject];
	
	// Origin is already determined.
	P2.isOrigin = NO;
	
	// Set the output dimensions for this node to be N-dimensional.
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
		[GCGraph insertNode:P2 projection:self.projection];
	}
	@catch (NSException *exception) {
		
		// Handle the error/exception.
		[self handleException:exception];
	}
	@finally {
		
		// Update the log.
		[log appendFormat:@"<li>We then map <font color=#FFFF00><strong>%@</strong></font> "
		 "corresponding to point <strong>P[%lu]</strong>,<br />"
		 "<font color=#AAFFAA><strong>%@</strong></font>", P2.identifier, nodeIdx, P2];
		
		// Increment the index counter.
		++nodeIdx;
	}
	
	/**
	 *	At this stage, we assume a successful building of an orthonormal space and as such,
	 *	we have placed three points, P0, P1, and P2 respectfully in an N-dimensional space.
	 *
	 *	For the case of equality (numberOfNodes = N),
	 *	the process is reduced down to the 2-dimensional GC approach (where N = 2),
	 *	where N denotes the number of dimensions of our measured space.
	 */
	PKNode *Pi = nil;
	
	/**
	 *  Components P(i,j), for i = 1, ..., N and j = 0, ..., i − 1, form a set of N(N + 1) / 2 unknowns,
	 *	and are therefore determined first.
	 */
	
	// We consider the first "N" points to define a coordinate system in N-dimensions.
	if (numberOfNodes > numberOfDimensions && [nodeEnumerator hasMoreObjects]) {
		
		// Find the next (i)th node.
		Pi = [nodeEnumerator nextObject];
		
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
				PKNode *nodeAtK1 = [GCGraph nodeAtIndex:(k + 1)];
				
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
			
			// Attempt to hide negligible values.
//			if (sum1 < -1.0E-4) { // -0.00001 | fabs(difference).
//				
//				NSLog(@"Attempt to hide negligible values: %g", sum1);
//				sum1 = 0.0;
//			}

			// Update Pi's position.
			[positions replaceObjectAtIndex:(dimension - 1) withObject:@(sqrt(sum1))];
			
			Pi.positions = positions;
			
			// Update Pi's position vector.
			[Pi updatePosition];
			
			@try { // Adding the new node to the projection model.
				
				// Does not throw an exception at this stage.
				[GCGraph insertNode:Pi projection:self.projection];
			}
			@catch (NSException *exception) {
				
				// Handle the error/exception.
				[self handleException:exception];
			}
			@finally {
				
				// Update the log.
				[log appendFormat:@"<li>Set <font color=#FFFF00><strong>%@</strong></font>, as the "
				 "(<strong>%lu</strong>)th ordered point <strong>P[%lu]</strong>,"
				 "<br /><font color=#AAFFAA><strong>%@</strong></font>",
				 Pi.identifier, nodeIdx, Pi.number, Pi];
				
				// Increment the index counter.
				++nodeIdx;
				
				// Find the next (i)th node.
				Pi = [nodeEnumerator nextObject];
				
				// Origin is already determined.
				Pi.isOrigin = NO;
				
				// Set the output dimensions for this node to be N-dimensional.
				Pi.numberOfDimensions = numberOfDimensions;
			}
		}
	}
	
	/**
	 *	The remaining points are computed as tetrahedra with base P0P1P2.
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
				PKNode *nodeAtK1 = [GCGraph nodeAtIndex:(k + 1)];

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
			
			// Attempt to hide negligible values.
//			if (sum1 < -1.0E-4) { // -0.00001 | fabs(difference).
//				
//				NSLog(@"Attempt to hide negligible values: %g", sum1);
//				sum1 = 0.0;
//			}

			// Update Pi's position.
			[positions replaceObjectAtIndex:(numberOfDimensions - 1) withObject:@(sqrt(sum1))];
			
			Pi.positions = positions;
			
			// Update Pi's position vector.
			[Pi updatePosition];
			
			// Get a reference to the node at index (numberOfDimensions).
			PKNode *Pn = [GCGraph nodeAtIndex:numberOfDimensions];
			
			// distance(Pn, Pi);
			
			double PnPi = [self.graph edgeFromIndex:Pn.number // numberOfDimensions | (numberOfDimensions + 1).
											toIndex:Pi.number].weight.doubleValue;
			
			// distance(Pn "new", Pi);
			double newPnPi = (self.projection.distanceMetric == PKEuclidean) ?
			[[Pn positions] euclideanDistance:Pi.positions] :
			[[Pn positions] manhattanDistance:Pi.positions];
			
			// Get a copy of Pi.
			PKNode *flippedPi = Pi.clone;
			
			// Negate the last coordinate.
			[flippedPi replacePositionAtIndex:(numberOfDimensions - 1)
								   withObject:@(-[[Pi positionAtIndex:(numberOfDimensions - 1)] doubleValue])];
			
			// Update flippedPi's position vector.
			[flippedPi updatePosition];
			
			// newFlippedPnPi := DistancenD(PointNumber[NrDimensions + 1], PointNumber[i]);
			double newFlippedPnPi =
			(self.projection.distanceMetric == PKEuclidean) ?
			[[Pn positions] euclideanDistance:flippedPi.positions] :
			[[Pn positions] manhattanDistance:flippedPi.positions];
			
			/**
			 *	We introduced a tolerance factor (epsilon).
			 *  Updated (18/4/2014).
			 *	Deprecated (15/09/2014).
			 *
			 *	const float epsilon = 0.8f; // 1.0E-4f;
			 *	float tolerance = 0.0;
			 */
			
			/**
			 *	If ABS(PnPi - newFlippedPnPi) < ABS(PnPi - newPnPi),
			 *	then we affirm the flipping.
			 */
			if (fabs(PnPi - newFlippedPnPi) < fabs(PnPi - newPnPi)) {
				
				// Set the coords for the flipped copy of Pi, having Pi.z in the "negative" z-domain.
				// Negate the last coordinate.
				[Pi replacePositionAtIndex:(numberOfDimensions - 1)
								withObject:@(-[[Pi positionAtIndex:(numberOfDimensions - 1)] doubleValue])];
				
				// Update Pi's position vector.
				[Pi updatePosition];
				
				// Update the flipped status.
				Pi.flipped = YES;
			}
			
			@try { // Adding the new node to the projection model.
				
				// Does not throw an exception at this stage.
				[GCGraph insertNode:Pi projection:self.projection];
			}
			@catch (NSException *exception) {
				
				// Handle the error/exception.
				[self handleException:exception];
			}
			@finally {
				
				// Update the log.
				[log appendFormat:@"<li>Set <font color=#FFFF00><strong>%@</strong></font>, as the "
				 "(<strong>%lu</strong>)th ordered point <strong>P[%lu]</strong>,"
				 "<br /><font color=#AAFFAA><strong>%@</strong></font>",
				 Pi.identifier, nodeIdx, Pi.number, Pi];
				
				// Increment the index counter.
				++nodeIdx;
				
				// Find the (i)th nearest neighbor to P(i - 1).
				Pi = [nodeEnumerator nextObject];
				
				// Origin is already determined.
				Pi.isOrigin = NO;
				
				// Set the output dimensions for this node to be N-dimensional.
				Pi.numberOfDimensions = numberOfDimensions;
			}
		}
	}
	
	// Unordered list (fold).
	[log appendString:@"</ul>"];
	
	// Call our completion handler with the result of our processing.
	if (![self isCancelled]) {
		
		// Pass a successful projection operation to the post-processing handler.
		if (self.completionHandler)
			self.completionHandler(GCGraph,
								   nil,
								   nil,
								   nil,
								   self.startIndex,
								   CFAbsoluteTimeGetCurrent() - timeSinceOperation,
								   log);
		
	} else { // failed or cancelled.
		
		NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
											 code:kPKErrorCode
										 userInfo:@{NSLocalizedDescriptionKey:@"Algorithm failed or cancelled."}];
		
		// Pass a failed operation to the error handler.
		if (self.errorHandler)
			self.errorHandler(error);
	}
}

@end
