//
//  PKTriangularProjection.m
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

#import "PKTriangularProjection.h"

#import <GLKit/GLKVector3.h>

@implementation PKTriangularProjection

#pragma mark -
#pragma mark Creating

/**
 *	The Triangular Projection (TP2) algorithm.
 *	Returns the 2-dimensional projection graph of the input graph.
 *
 *	@param	graph				An edge-weighted, undirected graph; each value in input is an array of values of a single variable for each data point.
 *	@param	start				A starting index.
 *	@param	dimensions			An array of dimensions (column indices).
 *	@param	minimumArea			A "Minimum Area" property flag.
 *	@param	minimumPerimeter	A "Minimum Perimeter" property flag.
 *  @param	numberOfIterations	The maximum number of iterations.
 *	@param	projectionType		A projection type (2-dimensional).
 *  @param	completionHandler	A completion handler.
 *  @param	errorHandler		An error handler.
 *
 *	@return	The new algorithm operation.
 */
+ (instancetype)triangularProjectionWithGraph:(id<PKGraphDelegate>)graph
									fromIndex:(NSUInteger)start
								   dimensions:(PKIntegerArray *)dimensions
								  minimumArea:(BOOL)minimumArea
							 minimumPerimeter:(BOOL)minimumPerimeter
						   numberOfIterations:(NSUInteger)numberOfIterations
							   projectionType:(PKProjectionType)projectionType
							completionHandler:(PKCompletionBlock)completionHandler
								 errorHandler:(PKErrorBlock)errorHandler
{
	// Immutable TP2 operation, just return a new reference to itself (retained automatically by ARC).
	return [[[self class] alloc] initWithGraph:graph
									 fromIndex:start
									dimensions:dimensions
								   minimumArea:minimumArea
							  minimumPerimeter:minimumPerimeter
							numberOfIterations:numberOfIterations
								projectionType:projectionType
							 completionHandler:completionHandler
								  errorHandler:errorHandler];
}

#pragma mark -
#pragma mark Initializing

/**
 *	Designated initializer.
 *	Initializes a Triangular Projection (TP2) operation of the input graph.
 *	Called when an instance is passed to an NSOperationQueue.
 *
 *	@param	graph				An edge-weighted, undirected graph; each value in input is an array of values of a single variable for each data point.
 *	@param	start				A starting index.
 *	@param	dimensions			An array of dimensions (column indices).
 *	@param	minimumArea			A "Minimum Area" property flag.
 *	@param	minimumPerimeter	A "Minimum Perimeter" property flag.
 *  @param	numberOfIterations	The maximum number of iterations.
 *	@param	projectionType		A projection type (2-dimensional).
 *  @param	completionHandler	A completion handler.
 *  @param	errorHandler		An error handler.
 *
 *	@return	The new algorithm operation.
 */
- (instancetype)initWithGraph:(id<PKGraphDelegate>)graph
					fromIndex:(NSUInteger)start
				   dimensions:(PKIntegerArray *)dimensions
				  minimumArea:(BOOL)minimumArea
			 minimumPerimeter:(BOOL)minimumPerimeter
		   numberOfIterations:(NSUInteger)numberOfIterations
			   projectionType:(PKProjectionType)projectionType
			completionHandler:(PKCompletionBlock)completionHandler
				 errorHandler:(PKErrorBlock)errorHandler
{
	// Immutable TP2, just return a new reference to itself (retained automatically by ARC).
	self = [super init];
	
	if (self) {
		
		// Initialization code.
		self.name = @"Triangular Projection";
		self.graph = graph;
		self.startIndex = start;
		self.finishIndex = 0;
		self.dimensions = dimensions;
		self.mapNNC = YES;
		self.mapEmanatingEdges = YES;
		self.projectionType = projectionType;
		self.completionHandler = completionHandler;
		self.errorHandler = errorHandler;
		
		// Establish an Euclidean distance calculation method by default.
		self.distanceMetric = PKEuclidean;
		
		// Setup a table entry array.
		self.tableEntry = [PKArray arrayWithLength:graph.numberOfNodes];
		
		// For each table entry, setup a new algorithm entry record, based on the current node count.
		for (NSUInteger idx = 0;
			 idx < graph.numberOfNodes;
			 ++idx) {
			
			// Add a new algorithm entry record.
			[self.tableEntry replaceObjectAtIndex:idx withObject:[[PKAlgorithmEntry alloc] init]];
		}
		
		// Determine the projection mode.
		if (minimumArea) {
			
			self.minimumDistance = NO;
			self.minimumArea = YES;
			self.minimumPerimeter = NO;
			
		} else if (minimumPerimeter) {
			
			self.minimumDistance = NO;
			self.minimumArea = NO;
			self.minimumPerimeter = YES;
			
		} else { // Minimum Distance.
			
			self.minimumDistance = YES;
			self.minimumArea = NO;
			self.minimumPerimeter = NO;
		}
		
		// Set the max number of enumerations to either the input number or to (100).
		if (numberOfIterations > 0)
			_numberOfIterations = numberOfIterations;
		else
			_numberOfIterations = graph.numberOfNodes * (NSUInteger)1E2;
		
		// Set the number of iterations to 0.
		_iteration = 0;
		
		// Start := 1.0, Ende := 0.01.
		_lambda = 1.0;
	}
	
	// Return this TP2 operation.
	return self;
}

#pragma mark -
#pragma mark Accessing

/**
 *  An array of dimensions (column indices).
 */
@synthesize dimensions = _dimensions;

/**
 *  A table entry array.
 */
@synthesize tableEntry = _tableEntry;

/**
 *	A minimum distance flag.
 *
 *	@discussion	If ABS(PnPi - newFlippedPnPi) < ABS(PnPi - newPnPi), then we affirm the flipping.
 */
@synthesize minimumDistance = _minimumDistance;

/**
 *	A minimum perimeter flag.
 *
 *	@discussion	Enable to consider all possible outside edges P0 and P1 and choose P2 using the "Minimum Distance" property.
 */
@synthesize minimumPerimeter = _minimumPerimeter;

/**
 *	A minimum area flag.
 *
 *	@discussion	We consider all possible pairs of P0 and P1 which form an edge on the outside of the triangulation.
 *	An edge is on the outside of the triangulation if it has never been chosen or has only been chosen once.
 *	For each choice of P0 and P1, we choose P2 which leads to the triangle with the smallest area,
 *	and we pick the triangle of points P0, P1 and P2 which has the smallest area..
 */
@synthesize minimumArea = _minimumArea;

/**
 *  A Nearest Neighbor Chain (NNC) mapping sequence flag.
 *
 *	@discussion	Enable to reveal the NNC mapping sequence.
 */
@synthesize mapNNC = _mapNNC;

/**
 *  An emanating edges mapping sequence flag.
 *
 *	@discussion	Enable to reveal the emanating edges mapping sequence from the seed node.
 */
@synthesize mapEmanatingEdges = _mapEmanatingEdges;

/**
 *  Projection distance metrics.
 *	Defines which distance calculation method to adopt.
 */
@synthesize distanceMetric = _distanceMetric;

/**
 *  Reduced with every iteration of the algorithm.
 *
 *	@discussion	Used to reduce the error obtained from each iteration.
 */
@synthesize lambda = _lambda;

/**
 *  The maximum number of iterations reachable.
 */
@synthesize numberOfIterations = _numberOfIterations;

/**
 *   Tracks the number of iterations.
 */
@synthesize iteration = _iteration;

/**
 *  Index array (I).
 */
@synthesize indicesI = _indicesI;

/**
 *  Index array (J).
 */
@synthesize indicesJ = _indicesJ;

#pragma mark -
#pragma mark Querying

/**
 *  Returns the closest, or nearest neighbor to a given node.
 *
 *	@param	preVisitor	A visitor.
 *	@param	postVisitor	A visitor.
 *  @param	node		A node.
 *  @param	visited		A visited integer array.
 *
 *  @return The nearest neighbor.
 */
- (PKNode *)nearestNeighborWithPreVisitor:(PKVisitor)preVisitor
							  postVisitor:(PKVisitor)postVisitor
									 node:(PKNode *)node
								  visited:(PKIntegerArray *)visited
{
	// Mark it as pre-visited.
	if (preVisitor != NULL)
		preVisitor(node);
	
	// Establish a nearest neighbor to return.
	PKNode *nearestNeighbor = nil;

	// Establish the smallest initial weight.
	double minimumWeight = DBL_MAX;

	// Establish a node entry.
	PKAlgorithmEntry *nodeEntry = [self.tableEntry objectAtIndex:node.number];

	// Mark as known.
	nodeEntry.known = YES;

	// Loop throgh all emanating edges from that node.
	for (PKEdge *edge in node.emanatingEdges) {
		
		// Establish the mate node.
		PKNode *mate = [edge mateOfNode:node];
		double weight = edge.weight.doubleValue;
		
		// In order to ensure that each node is visited at most once,
		// an array of length |V| of BOOL values called (visited) is used (as an NSMutableDictionary).
		// That is, visited[index] = true only if node (index) has been visited.
		if (node.number != mate.number &&
			![visited integerAtIndex:mate.number] &&
			weight < minimumWeight) {
			
			// Found the entry.
			minimumWeight = weight;
			
			// We therefore assign this node as the nearest neighbor.
			nearestNeighbor = mate;
		}
	}
	
	// Mark it as post-visited.
	if (postVisitor != NULL)
		postVisitor(node);

	// Mark this node as visited.
	if (nearestNeighbor) {
		
		// Establish a mate entry.
		PKAlgorithmEntry *mateEntry = [self.tableEntry objectAtIndex:nearestNeighbor.number];
		mateEntry.distance = minimumWeight;
		mateEntry.predecessor = node.number;

		// Mark this node as visited.
		[visited replaceIntegerAtIndex:nearestNeighbor.number withInteger:YES];
	}

	// Return the nearest neighbor.
	return nearestNeighbor;
}

/**
 *  Returns the next connecting node in the MST to a given node.
 *
 *  @param index A head node.
 *
 *  @return The next connecting node.
 */
- (PKNode *)successorInMinimumSpanningTreeToNode:(PKNode *)node
{	
	// For each table entry, look up each predecessor of this node.
	NSUInteger idx = 0;
	
	// Loop throgh each node entry.
	for (id<PKAlgorithmEntryDelegate> nodeEntry in self.tableEntry) {
		
		// Look up a matching predecessor.
		if (nodeEntry.predecessor == node.number) {
			
			// Found the entry.
			// We therefore return the node at this index.
			return [self.graph nodeAtIndex:idx];
		}
		
		// Move on.
		++idx;
	}
	
	// Return nothing.
	return nil;
}

#pragma mark -
#pragma mark Operating

/**
 *  Constructs a Minimum Spanning Tree (MST) via assigning table entry references.
 *
 *  @param node A node.
 */
- (void)constructMinimumSpanningTreeFromNode:(PKNode *)node
{
	// Initialize a priority queue.
	id<PKPriorityQueueDelegate> queue = [[PKBinaryHeap alloc] initWithCapacity:self.graph.numberOfEdges];
	
	// Enqueue the first visited value.
	[queue enqueue:[PKKeyValuePair pairWithKey:@(0.0) value:node]];
	
	// At each step, we select an edge with the smallest weight that connects the tree to a node not yet in the tree.
	while (!queue.isEmpty) {
		
		// Dequeue the smallest node entry.
		PKKeyValuePair *pair = [queue dequeueMinimum];
		PKNode *head = pair.value;
		NSUInteger headNumber = head.number;
		
		// Establish a head entry.
		PKAlgorithmEntry *headEntry = [self.tableEntry objectAtIndex:headNumber];
		
		// If head entry is not known.
		if (!headEntry.known) {
			
			// Mark as known.
			headEntry.known = YES;
			
			// Loop throgh all emanating edges from the head node.
			for (PKEdge *edge in head.emanatingEdges) {
				
				// Establish the tail node.
				PKNode *tail = [edge mateOfNode:head];
				NSUInteger tailNumber = tail.number;
				double distance = edge.weight.doubleValue;
				
				// Establish a head entry.
				PKAlgorithmEntry *tailEntry = [self.tableEntry objectAtIndex:tailNumber];
				
				// Find the smallest edge emanating from the head entry.
				if (!tailEntry.known && tailEntry.distance > distance) {
					
					tailEntry.distance = distance;
					tailEntry.predecessor = headNumber;
					
					// Enqueue the smallest edge emanating from the head entry.
					[queue enqueue:[PKKeyValuePair pairWithKey:@(distance) value:tail]];
				}
			}
		}
	}
}

/**
 *  Reduces Lambda, uppercase (Λ) lowercase (λ), according to the iterations.
 */
- (void)reduceLambda
{
	// Increment by 1.
	++_iteration;
	
	// Derivation of the approach: y(t) = k.exp(-l.t).
	double ratio = (double)self.iteration / self.numberOfIterations;
	
	// Start := 1.0, Ende := 0.01.
	_lambda = pow(0.01, ratio);
}

@end
