{ include("human_actions.asl")}
{ register_function("rjs.function.length_allow_unground") } 

isMovementRelatedToActions(Predicate,ActionList) :-
	jia.findall(
		ActPred,
		action(ActPred,Preconditions,Movement,ProgressionEffects,NecessaryEffect) &
		jia.member_same_type(Predicate,Movement),
		ActionList
	)
	& rjs.function.length_allow_unground(ActionList) > 0.

arePredicatesInListTrue(List) :- 
	.count(
		.member(Predicate,List) & 
		Predicate, 
		Count
	) 
	& rjs.function.length_allow_unground(List) == Count.

isProgressionEffect(Predicate,ActionList) :-
	.findall(
		ActPred,
		action(ActPred,Preconditions,Movement,ProgressionEffects,NecessaryEffect) &
		jia.member_same_type(Predicate,ProgressionEffects),
		ActionList
	)
	& rjs.function.length_allow_unground(ActionList) > 0.
	
matchingStartedActions(Predicate,ActionList,ActionList2) :-
	.findall(
		ActPred,
		possibleStartedActions(PossibleActionList) &
		.member(ActPred,ActionList) &
		.member(ActPred,PossibleActionList),
		ActionList2
	)
	& rjs.function.length_allow_unground(ActionList2) > 0.
	
isNecessaryEffect(Predicate,ActionList) :-
	.findall(
		ActPred,
		action(ActPred,Preconditions,Movement,ProgressionEffects,NecessaryEffect) &
		jia.member_same_type(Predicate,NecessaryEffect),
		ActionList
	)
	& rjs.function.length_allow_unground(ActionList) > 0.		
	
matchingProgressingActions(Predicate,ActionList,ActionList2) :-
	.findall(
		ActPred,
		possibleProgressingActions(ProgressingActionList) &
		.member(ActPred,ActionList) &
		.member(ActPred,ProgressingActionList),
		ActionList2
	)
	& rjs.function.length_allow_unground(ActionList2) > 0.

!start.

// trigger with an action -> action started
@startedS[atomic]
+NewPredicate[source(percept)] :  isMovementRelatedToActions(NewPredicate,ActionList) <-
	!addPossibleStartedActions(ActionList).	
	
+!addPossibleStartedActions(ActionList) : possibleStartedActions(ActionListPrev) & .intersection(ActionList,ActionListPrev,I) & .length(I)==.length(ActionList) <-
	-possibleStartedActions(ActionListPrev);
	+possibleStartedActions(ActionList).

+!addPossibleStartedActions(ActionList) : true <-
	+possibleStartedActions(ActionList).

// from action started -> action progressing
@progressS1[atomic]
+NewPredicate[source(percept)] :isProgressionEffect(NewPredicate,ActionList) 
							   & matchingStartedActions(Predicate,ActionList,ActionList2) <-
	++possibleProgressingActions(ActionList2).

// from action started or action progressing -> action over	
@overS[atomic]
+NewPredicate[source(percept)] : isNecessaryEffect(NewPredicate,ActionList) 
							   & (matchingProgressingActions(Predicate,ActionList,ActionList2) | matchingStartedActions(Predicate,ActionList,ActionList2))<-
	++possibleFinishedActions(ActionList2).

// trigger with a progression effect -> action progressing
// no check to see if it exists a possible human agent has all progression effect predicates have a human as object or subject
@progressS2[atomic]
+NewPredicate[source(percept)] : isProgressionEffect(NewPredicate,ActionList) <-
	++possibleProgressingActions(ActionList).

// trigger with a necessary effect -> action over
@overS2[atomic]
+NewPredicate[source(percept)] : isNecessaryEffect(NewPredicate,ActionList) & jia.exist_possible_agent(ActionList,ActionList2) <-
	++possibleFinishedActions(ActionList2).
	
// wait for an effect after an observed movement finished
@unknownS
-NewPredicate[source(percept)] :  isMovementRelatedToActions(NewPredicate,ActionList) 
								& possibleStartedActions(ActionList) <-
		.wait(possibleProgressingActions(A) & .intersection(A,ActionList,I) & .length(I)==.length(A)) 
	||| .wait(possibleFinishedActions(A) & .intersection(A,ActionList,I)  & .length(I)==.length(A))
	||| !timeoutMovement(ActionList).

+!timeoutMovement(ActionList) : true <-
	.wait(5000);
	-possibleStartedActions(ActionList).
	
+possibleProgressingActions(ActionList) : true <-
	.wait(possibleFinishedActions(A) & .sublist(A,ActionList))
	||| !timeoutProgressing(ActionList).

// TODO timeout should be action type dependent
+!timeoutProgressing(ActionList) : true <-
	.wait(10000);
	-possibleProgressingActions(ActionList);
	.findall(possibleStartedActions(L), possibleStartedActions(L) & .intersection(L,ActionList,I) & .length(I)==.length(ActionList),BelList);
	for(.member(B,BelList)){
		-B;
	}.
	
	
//test pick
//+!start : true <-
//	rjs.jia.log_beliefs;
//	.verbose(2);
//	.wait(1000);
//	+handEmpty("human_0")[source(percept)];
//	+isOn("cube_GGTB","table_1")[source(percept)];
//	+isOn("cube_BGTB","table_1")[source(percept)];
//	+isOn("szszsz","table_1")[source(percept)];
//	.wait(1000);
//	++handMovingToward("human_0",["cube_GGTB","obj2","cube_BGTB"])[source(percept)];
//	.wait(2000);
////	--handMovingToward("human_0",["cube_GGTB","obj2","cube_BGTB"])[source(percept)];
////	.wait(2000);
//	++hasInHand("human_0","cube_GGTB")[source(percept)];
//	.wait(2000);
//	--isOn("cube_GGTB","table_1")[source(percept)];
//	++~isOn("cube_GGTB","table_1")[source(percept)].
	
//test place
//+!start : true <-
//	rjs.jia.log_beliefs;
//	.verbose(2);
//	.wait(1000);
//	+bouh;
//	+hasInHand("human_0","cube_GGTB")[source(percept)];
//	+hasInHand("human_0","cube_BBCG")[source(percept)];
//	.wait(1000);
//	++handMovingToward("human_0",["table_1","obj2","cube_BGTB"])[source(percept)];
//	.wait(2000);
//	++handMovingToward("human_0",["table_1"])[source(percept)];
//	.wait(1000);
//	--handMovingToward("human_0",["table_1","obj2","cube_BGTB"])[source(percept)];
//	--hasInHand("human_0","cube_BBCG")[source(percept)];
//	+~hasInHand("human_0","cube_BBCG")[source(percept)];
//	.wait(2000);
//	+isOn("cube_BBCG","table_1")[source(percept)].
	
//test drop
//+!start : true <-
//	rjs.jia.log_beliefs;
//	.verbose(2);
//	.wait(1000);
//	+bouh;
//	+hasInHand("human_0","cube_GGTB")[source(percept)];
//	+hasInHand("human_0","cube_BBCG")[source(percept)];
//	.wait(1000);
//	++handMovingToward("human_0",["throw_box_green","table_1"])[source(percept)];
//	.wait(2000);
//	++handMovingToward("human_0",["throw_box_green"])[source(percept)];
//	--handMovingToward("human_0",["throw_box_green"])[source(percept)];
//	.wait(1000);
//	--hasInHand("human_0","cube_BBCG")[source(percept)];
//	+~hasInHand("human_0","cube_BBCG")[source(percept)];
//	.wait(2000);
//	+isIn("cube_BBCG","throw_box_green")[source(percept)].	

	