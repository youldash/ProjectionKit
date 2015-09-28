//
//  PKTriangularProjection.h
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

#import "PKAlgorithm.h"

/**
 *	Provides an interface for the distance-preserving Triangular Projection (TP2) algorithm.
 */
@interface PKTriangularProjection : PKAlgorithm

#pragma mark -
#pragma mark Accessing

/**
 *	An array of dimensions (column indices).
 */
@property (strong, nonatomic) PKIntegerArray *dimensions;

/**
 *	A table entry array.
 */
@property (strong, nonatomic) PKArray *tableEntry;

/**
 *	A minimum distance flag.
 *
 *	@discussion	If ABS(PnPi - newFlippedPnPi) < ABS(PnPi - newPnPi), then we affirm the flipping.
 */
@property (assign, nonatomic) BOOL minimumDistance;

/**
 *	A minimum perimeter flag.
 *
 *	@discussion	Enable to consider all possible outside edges P0 and P1 and choose P2 using the "Minimum Distance" property.
 */
@property (assign, nonatomic) BOOL minimumPerimeter;

/**
 *	A minimum area flag.
 *
 *	@discussion	We consider all possible pairs of P0 and P1 which form an edge on the outside of the triangulation.
 *	An edge is on the outside of the triangulation if it has never been chosen or has only been chosen once.
 *	For each choice of P0 and P1, we choose P2 which leads to the triangle with the smallest area,
 *	and we pick the triangle of points P0, P1 and P2 which has the smallest area..
 */
@property (assign, nonatomic) BOOL minimumArea;

/**
 *  A Nearest Neighbor Chain (NNC) mapping sequence flag.
 *
 *	@discussion	Enable to reveal the NNC mapping sequence.
 */
@property (assign, nonatomic) BOOL mapNNC;

/**
 *  An emanating edges mapping sequence flag.
 *
 *	@discussion	Enable to reveal the emanating edges mapping sequence from the seed node.
 */
@property (assign, nonatomic) BOOL mapEmanatingEdges;

/**
 *  Reduced with every iteration of the algorithm.
 *
 *	@discussion	Used to reduce the error obtained from each iteration.
 */
@property (assign, nonatomic) double lambda;

/**
 *	The maximum number of iterations reachable.
 */
@property (assign, nonatomic) NSUInteger numberOfIterations;

/**
 *	Tracks the number of iterations.
 */
@property (readonly, nonatomic) NSUInteger iteration;

/**
 *	Index array (I).
 */
@property (strong, nonatomic) PKIntegerArray *indicesI;

/**
 *	Index array (J).
 */
@property (strong, nonatomic) PKIntegerArray *indicesJ;

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
                                 errorHandler:(PKErrorBlock)errorHandler;

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
				 errorHandler:(PKErrorBlock)errorHandler;

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
								  visited:(PKIntegerArray *)visited;

/**
 *  Returns the next connecting node in the MST to a given node.
 *
 *  @param index A head node.
 *
 *  @return The next connecting node.
 */
- (PKNode *)successorInMinimumSpanningTreeToNode:(PKNode *)node;

#pragma mark -
#pragma mark Operating

/**
 *  Constructs a Minimum Spanning Tree (MST) via assigning table entry references.
 *
 *  @param node A node.
 */
- (void)constructMinimumSpanningTreeFromNode:(PKNode *)node;

/**
 *  Reduces Lambda, uppercase (Λ) lowercase (λ), according to the iterations.
 */
- (void)reduceLambda;

@end
